let Token = artifacts.require("./MobuToken.sol");
let Crowdsale = artifacts.require("./MobuCrowdsale.sol");


contract("Check contracts functionality", function(accounts) {

    it("deploy contracts", async () => {
        TokenInstance = await Token.deployed();
        CrowdsaleInstance = await Crowdsale.deployed(TokenInstance.address);
        console.log(TokenInstance.address);
        console.log(CrowdsaleInstance.address, web3.eth.accounts[0]);
    })

    
    it("check initialBalances", async () => {
        console.log(initialBalance = (await TokenInstance.balanceOf(web3.eth.accounts[0])).toString());
        console.log((await TokenInstance.balanceOf(TokenInstance.address)).toString());
    })


    it('sending tokens to Crowdsale contract', async () => {
        try {
            await TokenInstance.transfer(CrowdsaleInstance.address, initialBalance)
            assert.ok(true, "Transaction completed")
        } catch (error){
            assert.ok(false, "Transaction rejected")
        }
    });

    it('check tokens on Crowdsale contract', async () => {
        console.log((await TokenInstance.balanceOf(CrowdsaleInstance.address)).toString());
    })

    it('sending 1 ether to Crowdsale contract from accounts1', async () => {
        try {
            await CrowdsaleInstance.sendTransaction({from:web3.eth.accounts[1], value: Math.pow(10,18)})
            assert.ok(false, 'something went wrong');
        } catch (error){
            assert.ok(true, 'transaction must failed');
        }
    })
    it('must be equals zero', async () => {
        console.log('tokens = ' + (await TokenInstance.balanceOf(web3.eth.accounts[1])).toString() + ' tokens');
    })

    it('adding him to the whiteList', async () => {
        try {
            await CrowdsaleInstance.addToWhiteList([web3.eth.accounts[1]]);
            assert.ok(true);
        } catch (error){
            assert.ok(false, 'something went wrong')
        }
    })

    it('store owner ETH balance', async () => {
        console.log(ownersBalanceBefore = (await web3.eth.getBalance(web3.eth.accounts[0])).toString());
    })

    it('sending 1 ether to Crowdsale contract from accounts1 again', async () => {
        try {
            await CrowdsaleInstance.sendTransaction({from:web3.eth.accounts[1], value: Math.pow(10,18)})
            assert.ok(false, 'something went wrong');
        } catch (error){
            assert.ok(true, 'transaction must be failed');
        }
    })

    it('must be equals zero', async () => {
        console.log('1st account tokens = ' + (await TokenInstance.balanceOf(web3.eth.accounts[1])).toString() + ' tokens');
    })

    it('adding account2 to the whiteList not from owner', async () => {
        try {
            await CrowdsaleInstance.addToWhiteList([web3.eth.accounts[1]]);
            assert.ok(false, 'something went wrong');
        } catch (error){
            assert.ok(true, 'transaction must be failed')
        }
    })

    it('check owner ether balance changes', async () => {
        let currentBalanceAfter = (await web3.eth.getBalance(web3.eth.accounts[0]).toString())
        console.log(currentBalanceAfter)
        assert.ok((ownersBalanceBefore < currentBalanceAfter), 'OK')
    })

    it('check setCurrentRate function by owner', async () => {
        try {
            console.log('1ETH = $1000');
            await CrowdsaleInstance.setCurrentRate(100000)
            assert.ok(true, 'OK')
        } catch (error) {
            assert.ok(false, 'something went wrong')
        }
    })

    it('check setCurrentRate function not by owner', async () => {
        try {
            console.log('1ETH = $2000');
            await CrowdsaleInstance.setCurrentRate(200000, {from: web3.eth.accounts[1]})
            assert.ok(false, 'something went wrong')
        } catch (error) {
            assert.ok(true, 'OK')
        }
    })

    it ('add accouts 2 and 3 to the whiteList', async () => {
        try {
            await CrowdsaleInstance.addToWhiteList([web3.eth.accounts[2], web3.eth.accounts[3]]);
            assert.ok(true);
        } catch (error){
            assert.ok(false, 'something went wrong')
        }
    })

    it ('icoMinCap', async () => {
        console.log((await CrowdsaleInstance.icoMaxCap.call()).toString());
        console.log((await CrowdsaleInstance.ethCollected.call()).toString());
    })

    it ('buy tokens from account 2', async () => {
        try {
            await CrowdsaleInstance.sendTransaction({from:web3.eth.accounts[2], value: Math.pow(10,18)})
            assert.ok(true, 'OK');
        } catch (error){
            assert.ok(false, 'something went wrong');
        }
    })

    it ('check account 2 token balance', async () => {
        console.log('2nd account tokens = ' + (tokensFor1000USD = await TokenInstance.balanceOf(web3.eth.accounts[2])).toString() + ' tokens');
    })

    it('change currentRate by owner', async () => {
        try {
            console.log('1ETH = $2000');
            await CrowdsaleInstance.setCurrentRate(200000)
            assert.ok(true, 'OK')
        } catch (error) {
            assert.ok(false, 'something went wrong')
        }
    })

    it ('buy tokens from account 3', async () => {
        try {
            await CrowdsaleInstance.sendTransaction({from:web3.eth.accounts[3], value: Math.pow(10,18)})
            assert.ok(true, 'OK');
        } catch (error){
            assert.ok(false, 'something went wrong');
        }
    })

    it ('check account 3 token balance', async () => {
        console.log('3d account tokens = ' + (tokensFor2000USD = await TokenInstance.balanceOf(web3.eth.accounts[3])).toString() + ' tokens');
        assert.ok(tokensFor1000USD*2 == tokensFor2000USD*1);
    })

    it ('try to send tokens from accout 3', async () => {
        try {
            await TokenInstance.transfer(web3.eth.accounts[4], 1 ,{from: web3.eth.accounts[3]});
            assert.ok(false, 'something went wrong');
        }catch (error){
            assert.ok(true, 'OK')
        }
    })

    it ('try to call setIcoFinish to Token', async () => {
        try {
            await TokenInstance.setIcoFinish(12412412412);
            assert.ok(false, 'something went wrong');
        }catch (error){
            assert.ok(true, 'OK')
        }
    })
    it ('try to call setIcoFinish to Crowdsale', async () => {
        try {
            await CrowdsaleInstance.setIcoStage(12000, 12412412412);
            assert.ok(true, 'OK')
        } catch (error){
            assert.ok(false, 'something went wrong')
        }
    })
    it ('check ico finish in token contract', async () => {
        let icoFinish = await TokenInstance.icoFinish.call()
        assert(icoFinish.toString()/1 == 12412412412)
    })
    it ('try to release team tokens', async () => {
        try{
            await TokenInstance.releaseTeamTokens();
            assert.ok(false);
        }catch (error){
            assert.ok(true, 'OK')
        }
    })
    it ('try tot set Crowdsale contract again', async () => {
        try{
            await TokenInstance.setIcoFinish(web3.eth.accounts[2]);
            assert.ok(false);
        }catch (error){
            assert.ok(true, 'OK')
        }
    })

    it ('setup preIcoStage', async () => {
        try{
            await CrowdsaleInstance.setPreIcoStage(1,100);
            assert.ok(true, 'OK')
        }catch (error){
            assert.ok(false)
        }
    })
    it ('check preIcoStage', async () => {
        let start = await CrowdsaleInstance.preIcoStart.call();
        let finish = await CrowdsaleInstance.preIcoFinish.call();
        assert.ok(start/1 == 1 && finish/1 == 100)
    })

    it ('try to returnTokens', async () => {
        try {
            await CrowdsaleInstance.returnTokens();
            assert.ok(false);
        } catch(error){
            assert.ok(true, 'ok')
        }
    })
        
});