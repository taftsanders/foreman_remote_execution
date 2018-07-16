import React from 'react';

const UserInput = ({ target_id, preview, inputValues }) => (
  <div id="preview_{ target_id }" className="collapse out">
    <pre>{preview}</pre>
    {inputValues.length > 0 &&
      <table>
        <thead>
          <tr>
            <th>User input</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          {inputValues.map((input) => (
            <tr key={input.name}>
              <td><b>{input.name}</b></td>
              <td>{input.value}</td>
            </tr>
          ))}
        </tbody>
      </table>
    }
  </div>
)

export default UserInput;