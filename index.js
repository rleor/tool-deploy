const { exec } = require('child_process');
const runtime = require('regenerator-runtime')
const { AionKeystoreClient, AionLocalSigner } = require('@makkii/app-aion')
const config = require('./config.json')
const aion = new AionKeystoreClient()

console.log('private_key ' + config.private_key)

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
            console.log(signed_tx)
        })       
    }
})

