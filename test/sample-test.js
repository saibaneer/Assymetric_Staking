const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("License Contract", function () {
  let creator, commerce, admin, license;
  let alice, bob, charlie, david

  before(async function(){

    [alice, bob,charlie, david] = await ethers.getSigners();

    const Creators = await ethers.getContractFactory('Creators');
    creator = await Creators.deploy();
    await creator.deployed();
    console.log("Creator contract address is: ", creator.address);

    const Fees = await ethers.getContractFactory('Fees');
    admin = await Fees.deploy();
    await admin.deployed();
    console.log("Admin address is at: ", admin.address);

    const License = await ethers.getContractFactory('ImageLicense');
    license = await License.deploy(creator.address);
    await license.deployed();
    console.log("License contract is at: ", license.address);

    const Commerce = await ethers.getContractFactory("Commerce");
    commerce = await Commerce.deploy(license.address, admin.address, creator.address);
    await commerce.deployed();
    console.log("Commerce contract is at: ", commerce.address);

  })
  describe("Testing Main functions with creators and licenses", function(){
    it("should allow admin to set a fee", async function(){
      await admin.connect(alice).setFee(200);
      expect(await admin.connect(alice).getFee()).to.equal(200);
    })
    it("should add a new creator", async function(){
      expect(await creator.connect(alice).addCreator()).to.emit(creator, "NewCreator");
      const tx = await creator.connect(alice).viewCreatorInfo(alice.address);
      expect(tx.creatorAddress).to.equal(alice.address);
      expect(tx.isVerified).to.be.false;      
      // console.log(tx);
    })
    it("should allow a creator to create a standard license", async function(){
      const price = ethers.utils.parseEther("0.01");
      expect(
        await license.connect(alice).createStandardLicenseOnly(price)
      ).to.emit(license, "NewStandardLicense");
      const StandardLicenseEvent = license.filters.NewStandardLicense
      const event = await license.queryFilter(StandardLicenseEvent, "latest")
      const listingId = event[0].args.listingId.toString();

      const item = await license.connect(alice).viewImageLicense(listingId);
      // console.log(item);
      expect(item.listedBy).to.equal(alice.address);
      expect(item.standardPrice).to.equal(price);
      expect(item.standard).to.be.true;
      expect(item.extended).to.be.false;
      expect(item.available).to.be.true;
    });
    it("should NOT allow non-creators list an item", async function(){
       const price = ethers.utils.parseEther("0.01");
       try {
        await license.connect(bob).createStandardLicenseOnly(price);
       } catch (error) {
        assert(error.message.includes("ImageLicense__RegisterAsACreatorFirst()"));
        return;
       }
       assert(false);
    })
    it("should allow a user create Both licenses", async function(){
      const standardPrice = ethers.utils.parseEther("0.01");
      const extendedPrice = ethers.utils.parseEther("0.05");
      expect(
        await license
          .connect(alice)
          .createBothLicenses(standardPrice, extendedPrice)
      ).to.emit(license, "NewFullLicense");
      const LicenseEvent = license.filters.NewFullLicense;
      const event = await license.queryFilter(LicenseEvent, "latest");
      const listingId = event[0].args.listingId.toString();

      const item = await license.connect(alice).viewImageLicense(listingId);
      // console.log(item);
      expect(item.listedBy).to.equal(alice.address);
      expect(item.standardPrice).to.equal(standardPrice);
      expect(item.extendedPrice).to.equal(extendedPrice);
      expect(item.standard).to.be.true;
      expect(item.extended).to.be.true;
      expect(item.available).to.be.true;
    })
    it("should allow a creator to add extended license", async function(){
      const extendedPrice = ethers.utils.parseEther("0.055");
      expect(
        await license.connect(alice).addExtendedLicense(1, extendedPrice)
      ).to.emit(license, "AddExtendedLicense");
      const item = await license.connect(alice).viewImageLicense(1);
      // console.log(item);
      expect(item.listedBy).to.equal(alice.address);
      expect(item.extendedPrice).to.equal(extendedPrice);
    })
    it("should allow a creator to update a standard price", async function(){
      const updatedPrice = ethers.utils.parseEther("0.025");
      expect(
        await license.connect(alice).updateStandardLicensePrice(1, updatedPrice)
      ).to.emit(license, "UpdateStandardLicenseFee");
      const UpdatedEvent = license.filters.UpdateStandardLicenseFee;
      const event = await license.queryFilter(UpdatedEvent, "latest")
      // console.log(event[0].args)
      expect(event[0].args.oldPrice.toString()).to.equal("10000000000000000");
      expect(event[0].args.newPrice.toString()).to.equal("25000000000000000");
      expect(event[0].args.listingId.toString()).to.equal('1');
    })
    
    it("should allow a creator to update an extended price", async function () {
      const updatedPrice = ethers.utils.parseEther("0.075");
      const extendedPrice = ethers.utils.parseEther("0.055");
      expect(
        await license.connect(alice).updateExtendedLicensePrice(1, updatedPrice)
      ).to.emit(license, "UpdateExtendedLicenseFee");
      const UpdatedEvent = license.filters.UpdateExtendedLicenseFee;
      const event = await license.queryFilter(UpdatedEvent, "latest");
      // console.log(event[0].args)
      expect(event[0].args.oldPrice.toString()).to.equal("55000000000000000");
      expect(event[0].args.newPrice.toString()).to.equal("75000000000000000");
      expect(event[0].args.listingId.toString()).to.equal("1");
    });
    it("should allow a user to make an image unavailable", async function(){
      expect(await license.connect(alice).makeImageUnavailable(1)).to.emit(license, "RemoveLicenseAvailability");
       const item = await license.connect(alice).viewImageLicense(1);
       // console.log(item);
       expect(item.available).to.be.false;
    });
    it("should allow a user to make an image available", async function () {
      expect(await license.connect(alice).makeImageAvailable(1)).to.emit(
        license,
        "AddLicenseAvailability"
      );
      const item = await license.connect(alice).viewImageLicense(1);
      // console.log(item);
      expect(item.available).to.be.true;
    });
    it("should allow another user to buy a standard license", async function(){
      const purchasePrice = ethers.utils.parseEther("0.025");
      expect(
        await commerce.connect(bob).buyStandardLicense(1, alice.address, { value: purchasePrice })
      ).to.emit(commerce, "BoughtStandardLicense");
      const balance = await creator.creatorBalance(alice.address);
      assert.equal(balance.toString(), "24500000000000000");
    })
    it("should allow another user to buy an extended license", async function(){
      const purchasePrice = ethers.utils.parseEther("0.075");
      const newBalance = ethers.utils.parseEther("0.1");
      expect(
        await commerce.connect(bob).buyExtendedLicense(1, alice.address, { value: purchasePrice })
      ).to.emit(commerce, "BoughtFullLicense");
      const balance = await creator.creatorBalance(alice.address);
      assert.equal(balance.toString(), "98000000000000000");
    });
    it("should allow the user to withdraw their balance", async function(){
      const aliceBalanceBefore = await ethers.provider.getBalance(alice.address);
      console.log("Balance before is: ", aliceBalanceBefore);
      expect(await commerce.connect(alice).withdrawFundsForSeller(1)).to.emit(commerce, "WithdrewFundsForSeller");
      const aliceBalanceAfter = await ethers.provider.getBalance(alice.address);
      console.log("Balance after is: ", aliceBalanceAfter);
      const diff = aliceBalanceAfter - aliceBalanceBefore;
      // console.log("Difference is : ", diff);
      const balance = await creator.creatorBalance(alice.address);
      assert.equal(balance.toString(), "0");
    })
    it("should allow the admin to withdraw their funds", async function(){
      const prevBalance = await commerce.connect(alice).ownerHT(alice.address);
      console.log("Previous Balance was: ", prevBalance);
      const walletBalanceBefore = await ethers.provider.getBalance(alice.address);
      console.log("Admin Balance before withdrawal: ", walletBalanceBefore);
      await commerce.connect(alice).withdrawFundsForOwner();
      const walletBalanceAfter = await ethers.provider.getBalance(alice.address);
      console.log("Admin Balance after withdrawal: ", walletBalanceAfter);
      expect(await commerce.connect(alice).ownerHT(alice.address)).to.equal("0");
    })
    describe("Testing functions related with Staking", function (){
      let rewardToken, stakingToken, stakingContract;

      before(async function(){
        const Monion = await ethers.getContractFactory('StakingToken', david);
        stakingToken = await Monion.deploy(2000000);
        await stakingToken.deployed();

        const USDC = await ethers.getContractFactory("RewardPool", david);
        rewardToken = await USDC.deploy(500000);
        await rewardToken.deployed();

        const staking = await ethers.getContractFactory("AssymetricStaking", david);
        stakingContract = await staking.deploy(rewardToken.address, stakingToken.address, creator.address);
        await stakingContract.deployed();

        await stakingToken.connect(david).transfer(alice.address, 500);
        await stakingToken.connect(david).transfer(bob.address, 500);
        await stakingToken.connect(david).transfer(charlie.address, 500);

        await rewardToken.connect(david).transfer(stakingContract.address, 100000);

        await stakingToken.connect(alice).approve(stakingContract.address, 500);
        await stakingToken.connect(bob).approve(stakingContract.address, 500);
        


      })
      it("should NOT allow a non-creator to stake", async function(){
        try {
          await stakingContract.connect(bob).stake(300);
        } catch (error) {
          assert(error.message.includes("Staking__NotACreator()"));
          // console.log(error.message)
          return;
        }
        assert(false);
      })
      it("should allow a creator to stake", async function(){
        await stakingContract.connect(alice).stake(300);
        expect(await stakingContract.stakerBalance(alice.address)).to.equal(300)
      })
      it("should allow a creator to unstake their Monion", async function(){
        await stakingContract.connect(alice).unstake(100);
        expect(await stakingContract.stakerBalance(alice.address)).to.equal(200)
      })
      it("should make bob creator and allow bob stake at day 45", async function(){
        expect(await creator.connect(bob).addCreator()).to.emit(
          creator,
          "NewCreator"
        );
        const tx = await creator.connect(bob).viewCreatorInfo(bob.address);
        expect(tx.creatorAddress).to.equal(bob.address);
        expect(tx.isVerified).to.be.false;  

        const standardPrice = ethers.utils.parseEther("0.015");
        const extendedPrice = ethers.utils.parseEther("0.08");
        expect(
          await license
            .connect(bob)
            .createBothLicenses(standardPrice, extendedPrice)
        ).to.emit(license, "NewFullLicense");
        const LicenseEvent = license.filters.NewFullLicense;
        const event = await license.queryFilter(LicenseEvent, "latest");
        const listingId = event[0].args.listingId.toString();

        const item = await license.connect(bob).viewImageLicense(listingId);
        // console.log(item);
        expect(item.listedBy).to.equal(bob.address);
        expect(item.standardPrice).to.equal(standardPrice);
        expect(item.extendedPrice).to.equal(extendedPrice);
        expect(item.standard).to.be.true;
        expect(item.extended).to.be.true;
        expect(item.available).to.be.true;

        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60* 45]);
        await ethers.provider.send("evm_mine");

        await stakingContract.connect(bob).stake(300);
        expect(await stakingContract.stakerBalance(bob.address)).to.equal(300)
      })
      it("should make charlie creator and allow charlie stake at day 100", async function () {
        expect(await creator.connect(charlie).addCreator()).to.emit(
          creator,
          "NewCreator"
        );
        const tx = await creator.connect(charlie).viewCreatorInfo(charlie.address);
        expect(tx.creatorAddress).to.equal(charlie.address);
        expect(tx.isVerified).to.be.false;

        const standardPrice = ethers.utils.parseEther("0.015");
        const extendedPrice = ethers.utils.parseEther("0.08");
        expect(
          await license
            .connect(charlie)
            .createBothLicenses(standardPrice, extendedPrice)
        ).to.emit(license, "NewFullLicense");
        const LicenseEvent = license.filters.NewFullLicense;
        const event = await license.queryFilter(LicenseEvent, "latest");
        const listingId = event[0].args.listingId.toString();

        const item = await license.connect(charlie).viewImageLicense(listingId);
        // console.log(item);
        expect(item.listedBy).to.equal(charlie.address);
        expect(item.standardPrice).to.equal(standardPrice);
        expect(item.extendedPrice).to.equal(extendedPrice);
        expect(item.standard).to.be.true;
        expect(item.extended).to.be.true;
        expect(item.available).to.be.true;

        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60 * 55]);
        await ethers.provider.send("evm_mine");
        
        await stakingToken.connect(charlie).approve(stakingContract.address, 500);
        await stakingContract.connect(charlie).stake(400);
        expect(await stakingContract.stakerBalance(charlie.address)).to.equal(400);
      });
      it("should move the contract to the end of period and compute rewards factor", async function(){
        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60 * 21]);
        await ethers.provider.send("evm_mine");
        const balBefore = await stakingContract.totalRewardConstant_Owner();
        console.log("RewardFactor Balance before computation: ", balBefore);

        await stakingContract.connect(david).computeTotalRewardsConstant();
        const balAfter = await stakingContract.totalRewardConstant_Owner();
        console.log("RewardFactor Balance before computation: ", balAfter);
        assert(balAfter.toString() > balBefore.toString());
      })
      it("should confirm that total staked balance is valid", async function(){
        expect(await stakingContract.totalStakedBalance()).to.equal(900);
      })
      it("should get the deposit time for each staker", async function(){
        let aliceTime, bobTime, charlieTime, termination;
        aliceTime = await stakingContract.stakerToDepositTime(alice.address);
        console.log("Alice deposit time was: ", aliceTime)

        bobTime = await stakingContract.stakerToDepositTime(bob.address);
        console.log("Bob deposit time was: ", bobTime);

        charlieTime = await stakingContract.stakerToDepositTime(charlie.address);
        console.log("Charlie deposit time was: ", charlieTime);

        termination = await stakingContract.contractTermination();
        console.log("Termination time is: ", termination);
      })
      it("should NOT allow staking when contract termination date is passed", async function(){
        try {
          await stakingContract.connect(charlie).stake(50);
        } catch (error) {
          // console.log(error)
          assert(error.message.includes("Staking__StakingPeriodIsClosed()"));
          return;
        }
        assert(false);
      })
      it("should allow a user to claim rewards", async function(){
        const aliceRewardBalBefore = await rewardToken.balanceOf(alice.address);
        console.log("Alice's Balance of reward token before claim is: ", aliceRewardBalBefore);
        await stakingContract.connect(alice).claimRewards();

        const aliceRewardBalAfter = await rewardToken.balanceOf(alice.address);
        console.log(
          "Alice's Balance of reward token after claim is: ",
          aliceRewardBalAfter
        );
        assert(aliceRewardBalAfter.toString() > aliceRewardBalBefore.toString());
      })
      it("should allow a user to withdraw Monion", async function(){
        const aliceMonionBalBefore = await stakingToken.balanceOf(alice.address);
        console.log("Alice's Monion Balance before withdrawal is: ", aliceMonionBalBefore)
        expect(await stakingContract.connect(alice).withdrawMonion()).to.emit(stakingContract, "WithdrawAllMonion");
        const aliceMonionBalAfter = await stakingToken.balanceOf(alice.address);
        console.log("Alice's Monion Balance after withdrawal is: ", aliceMonionBalAfter);
        assert(aliceMonionBalAfter.toString() > aliceMonionBalBefore.toString());
      })
    });
    xdescribe("Testing functions with Mainnet Fork using WETH & DAI", function(){
      let WETH, DAI, Swapper;
      let wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
      let daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      before(async function(){
        WETH = await ethers.getContractAt("WETH9", wethAddress);
        DAI = await ethers.getContractAt(
          "contracts/interfaces/IERC20.sol:IERC20",
          daiAddress
        );

        const Uniswap = await ethers.getContractFactory("TestUniswap", david);
        Swapper = await Uniswap.deploy();
        await Swapper.deployed();
      });
      
    })
  })
  
});
