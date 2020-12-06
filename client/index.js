const readline = require('readline');
const { inspect } = require('util');
const WebSocket = require('ws');

const [,,name] = process.argv;

if (!name) throw new TypeError("name must be present");

const { BASE_URL: baseUrl = 'localhost:4000' } = process.env;

const url = `ws://${baseUrl}/ws/${name}`;
console.log(`Connecting to ${url}`);
const ws = new WebSocket(`ws://${baseUrl}/ws/${name}`);

ws.on('open', () => {
  ws.on('message', (data) => {
    console.log(data);
  });
  
  ws.on('error', (e) => {
    console.error(inspect(e));
    process.exit(1);
  });
  
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  rl.prompt();
  rl.on('line', (line) => {
    console.log(`Exec command ${line}`);
    ws.send(line);
    rl.prompt();
  });
});
