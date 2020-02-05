const http = require('http')
const runtime = require('regenerator-runtime')
const { AionKeystoreClient, AionLocalSigner } = require('@makkii/app-aion')
const config = require('./config.json')
const aion = new AionKeystoreClient()
const ABI = require('aion-web3-avm-abi');
const abi = new ABI();
const fs = require('fs')
console.log('[private_key]')
console.log(config.private_key)

function post(data, callback){

    let content = JSON.stringify(data)

    let options={
        host: config.rpc_ip,
        port: config.rpc_port,
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

// exec('xxd -plain dapp.jar', (err, stdout, stderr) => {
//     if (err) {
//         console.error(err)
//     } else {
//         let data = stdout.replace(/[\r\n]+/gm,"")
//         console.log('[data.length]')
//         console.log(data.length)
//         console.log('[data]')
//         console.log(data.substring(0, 8) + ' ...')
//         let unsigned_tx = {
//             nonce: 0,
//             type: 2,
//             data: '0x0001b9ae' + data,
//             gasPrice: 10000000000,
//             gasLimit: 5000000,
//         }
//         aion.signTransaction(unsigned_tx, new AionLocalSigner(), {
//             private_key: config.private_key
//         }).then((signed_tx) => {
//             console.log('[signed_tx.length]')
//             console.log(signed_tx.length)
//             console.log('[signed_tx]')
//             console.log(signed_tx.substring(0, 10) + ' ...')
//             post(signed_tx,(res)=>{
//                 console.log(res)
//             })
//         })
//     }
// })
function getNonce(addr){
    return new Promise(resolve=>{
        post({
            jsonrpc:"2.0",
            method:"eth_getTransactionCount",
            params:[addr],
            id:1,
        },res=>{
            res = JSON.parse(res)
            resolve(parseInt(res.result))}
        )
    })
}
async function execute(){
    const jar = fs.readFileSync('./dapp.jar')
    const data = abi.readyDeploy(jar, abi.encode([], []));
    console.log('[data.length]')
    console.log(data.length)
    const keypair = await aion.recoverKeyPairByPrivateKey(config.private_key);
    const nonce = await getNonce(keypair.address);
    console.log('[nonce]')
    console.log(nonce)
    let unsigned_tx = {
        nonce,
        type: '0x2',
        data: data,
        gasPrice: 10000000000,
        gasLimit: 5000000,
    }
    aion.signTransaction(unsigned_tx, new AionLocalSigner(), {
        private_key: config.private_key
    }).then((signed_tx) => {
        console.log('[signed_tx.length]')
        console.log(signed_tx.length)
        console.log('[signed_tx]')
        console.log(signed_tx.substring(0, 10) + ' ...')
        post({
            jsonrpc: "2.0",
            method: "eth_sendRawTransaction",
            params:[signed_tx],
            id:1,
        }, (res) => {
            console.log(res)
        })
    })
}

execute()
