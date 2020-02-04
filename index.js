const { exec } = require('child_process')
const http = require('http')
const runtime = require('regenerator-runtime')
const { AionKeystoreClient, AionLocalSigner } = require('@makkii/app-aion')
const config = require('./config.json')
const aion = new AionKeystoreClient()

console.log('private_key ' + config.private_key)

function post(data,fn){
    
    let content = JSON.stringify(data)
    
    let options={
        host: '127.0.0.1',
        port: 8545,
        method:'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': content.length
        }
    };
    let req = http.request(options, (res) => {
        let _data = '';
        res.on('data', (chunk)=>{
            _data += chunk;
        });
        res.on('end', ()=>{
            callback(_data)
        })
    })
    req.write(content);
    req.end();
}

exec('xxd -plain dapp.jar', (err, stdout, stderr) => {
    if (err) {
        console.error(err)
    } else {
        let data = stdout.replace(/[\r\n]+/gm,"")
        let unsigned_tx = {
            nonce: 0,
            type: 2,
            data: data
        }
        aion.signTransaction(unsigned_tx, new AionLocalSigner(), {
            private_key: config.private_key
        }).then((signed_tx) => {
            post(signed_tx,(res)=>{
                console.log(res)
            })
        })       
    }
})

