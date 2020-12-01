require 'base64'
require 'mqtt'
require 'json'

module ForemanRemoteExecutionCore
  class PollingScriptRunner < ScriptRunner

    DEFAULT_REFRESH_INTERVAL = 60
    BROKER = 'localhost'
    BROKER_PORT = 1883

    def self.load_script(name)
      script_dir = File.expand_path('../async_scripts', __FILE__)
      File.read(File.join(script_dir, name))
    end

    # The script that controls the flow of the job, able to initiate update or
    # finish on the task, or take over the control over script lifecycle
    CONTROL_SCRIPT = load_script('control.sh')

    # The script always outputs at least one line
    # First line of the output either has to begin with
    # "RUNNING" or "DONE $EXITCODE"
    # The following lines are treated as regular output
    RETRIEVE_SCRIPT = load_script('retrieve.sh')

    def initialize(options, user_method, suspended_action: nil)
      super(options, user_method, suspended_action: suspended_action)
      @callback_host = options[:callback_host]
      @task_id = options[:uuid]
      @step_id = options[:step_id]
      @otp = ForemanTasksCore::OtpManager.generate_otp(@task_id)
    end

    def prepare_start
      upload_control_scripts
    end

    def initialization_script
      close_stdin = '</dev/null'
      close_fds = close_stdin + ' >/dev/null 2>/dev/null'
      main_script = "(./script.sh #{close_stdin} 2>&1; echo $?>init_exit_code)"
      control_script_finish = "./control.sh init-script-finish"
      <<-SCRIPT.gsub(/^ +\| /, '')
      | export CONTROL_SCRIPT="$(readlink -f control.sh)"
      | export PERIODIC_UPDATE_INTERVAL=15
      | sh -c '#{main_script} | ./control.sh update; #{control_script_finish}' #{close_fds} &
      | echo $! > pid
      SCRIPT
    end

    def trigger(*args)
      payload = {
        "callback_host" => @callback_host,
        "task_id" => @task_id,
        "step_id" => @step_id,
        "otp" => @otp,
        "files" => [
          "control.sh", "retrieve.sh", "env.sh", "main.sh", "script.sh"
        ].map { |f| "/dynflow/tasks/store/#{@task_id}/#{@step_id}/#{f}" },
        "main" => "main.sh"
      }
      @logger.debug payload
      MQTT::Client.connect(BROKER, BROKER_PORT) do |c|
        c.publish("per-host/#{@host}", JSON.dump(payload), false, 1)
      end
    end

    def refresh
    end

    def external_event(event)
      data = event.data
      load_event_updates(data)
    end

    def close
      SmartProxyDynflowCore::Memstore.instance.drop(@task_id)
      ForemanTasksCore::OtpManager.drop_otp(@task_id, @otp)
    end

    def upload_control_scripts
      return if @control_scripts_uploaded

      {
        "env.sh" => env_script,
        "control.sh" => CONTROL_SCRIPT,
        "retrieve.sh" => RETRIEVE_SCRIPT,
        "script.sh" => sanitize_script(@script),
        "main.sh" => initialization_script
      }.each do |name, content|
        SmartProxyDynflowCore::Memstore.instance.add(@task_id, @step_id, name, content)
      end
      @control_script_uploaded = true
    end

    # Script setting the dynamic values to env variables: it's sourced from other control scripts
    def env_script
      <<~SCRIPT
        CALLBACK_HOST="#{@callback_host}"
        TASK_ID="#{@task_id}"
        STEP_ID="#{@step_id}"
        OTP="#{@otp}"
      SCRIPT
    end

    private

    # Generates updates based on the callback data from the manual mode
    def load_event_updates(event_data)
      continuous_output = ForemanTasksCore::ContinuousOutput.new
      if event_data.key?('output')
        lines = Base64.decode64(event_data['output']).sub(/\A(RUNNING|DONE).*\n/, '')
        continuous_output.add_output(lines, 'stdout')
      end
      new_update(continuous_output, event_data['exit_code'])
    end

    def cleanup
    end
  end
end
