pragma solidity ^0.4.22;
contract CarbonContract{
	struct EA{
	uint[] UserList;
	}
	struct user{
	uint uid;
	uint amount;
	uint remainAmount;
	uint[] did;
	uint[] thr;
	bool ifAccepted;
	}
	EA Ea;
	bool exit;
	
	mapping(uint => user) userList;
	mapping(uint=>uint[]) didCo2Used;
	mapping(uint=>uint[]) didCo2UsedOfAll;
	mapping(uint=>uint) userCI;
	
	event alertOver(uint uid,bool flag1,uint did,bool flag2);
	event checkUserEvent(bool flag);
	event rankSellerEvent(uint[] users);
	event overSell(uint uid);
	event notAllowTrade(uint uid);
	event queryBuyerAmount(uint amount);
	event querySellerAmount(uint amount);
	
	function upUserToEA(uint uid,uint8 amount)public{
		Ea.UserList.push(uid);
		userList[uid].amount = amount;
		userList[uid].remainAmount = amount;
	}
	
	function checkUserFunc(EA memory ea , uint[] memory uid) internal {
		EA memory tmp = ea;
		uint length = tmp.UserList.length;
		for(uint i=0;i<length;i++)
			if (uid[0] == tmp.UserList[i]){
			exit  = true;
			break;
		}
	}
	
	function checkUser(uint[] memory uid)public returns(bool){
		checkUserFunc(Ea,uid);
		bool state = exit;
		exit = false;
		emit checkUserEvent(state);
		return state;
	}
	
	function setThr(uint uid,uint did,uint thr)public{
		userList[uid].did.push(did);
		userList[uid].thr.push(thr);
	}
	
	uint wj = 7;
	uint pj = 11;
	uint o = 5;
	uint b = 2;
	uint y = 0;
	uint u = 172;
	
	function Analyze (uint uid,uint did,uint co2Used)private returns(uint thr,uint usedAllOfDid,uint CI){
		didCo2Used[did].push(co2Used);
		didCo2UsedOfAll[uid].push(co2Used);
		uint length = didCo2Used[did].length;
		usedAllOfDid = 0;
		for(uint i=0;i<length;i++){
			usedAllOfDid = usedAllOfDid + didCo2Used[did][i];
		}
		uint dlength = userList[uid].did.length;
		uint num = 0;
		for(uint z=0;z<dlength;z++){
			if(did == userList[uid].did[z])
			num = z;
		}
        thr = userList[uid].thr[num];
		uint para1 = usedAllOfDid * wj * pj * 44/12 * o;
		uint para2 = para1 * b;
		uint TCE = para1 + para2 + y;
		CI = TCE / u;
		return (thr,usedAllOfDid,CI);
	}
	
	function receiveData(uint uid,uint did,uint co2Used)public returns(string){
		uint thr;
		uint usedAllOfDid;
		uint CI;
		(thr,usedAllOfDid,CI) = Analyze(uid,did,co2Used);
		userCI[uid] = CI;
		uint amount = userList[uid].amount;
		uint allLength = didCo2UsedOfAll[uid].length;
		uint usedAllUsed = 0;
		for(uint j=0;j<allLength;j++){
			usedAllUsed = usedAllUsed + didCo2UsedOfAll[uid][j];
		}
		userList[uid].remainAmount = amount - usedAllUsed;
		
		if(usedAllOfDid >= thr && userList[uid].remainAmount<=0 )
		{	emit alertOver(uid,true,did,true);
			return "the device over and the user over";
		}
		else if(usedAllOfDid >= thr && userList[uid].remainAmount>0)
		{	emit alertOver(uid,false,did,true);
			return "the device over but the user not over";
		}
		else if(usedAllOfDid < thr && userList[uid].remainAmount<=0)
		{	emit alertOver(uid,true,did,false);
			return "the device not over but the user over";
		}
		else if(usedAllOfDid < thr && userList[uid].remainAmount>0)
		{
			emit alertOver(uid,false,did,false);
			return "the device not over and the user not over";
		}
	}
	
	function rankSeller()public constant returns(uint ,uint[]){
		EA memory temEa = Ea;
		uint ulength = temEa.UserList.length;
		uint temCI;
		for(uint p=0;p<ulength-1;p++){
			for(uint o=0;o<ulength-p-1;o++){
				uint uid1 = temEa.UserList[o];
				uint CI1 = userCI[uid1];
				uint uid2 = temEa.UserList[o+1];
				uint CI2 = userCI[uid2];
				if(CI1>CI2){
				temCI = temEa.UserList[o];
				temEa.UserList[o] = temEa.UserList[o+1];
				temEa.UserList[o+1] = temCI;			
				}
			}
		}
		emit rankSellerEvent(temEa.UserList);
		return (1,temEa.UserList);
	}
	
	function setTradeAccept(uint uid,bool flag){
		userList[uid].ifAccepted = flag;
	}
	
	function trade(uint buyerUid,uint sellerUid,uint amount){
		if(!userList[sellerUid].ifAccepted){
			emit notAllowTrade(sellerUid);
			return;
		}
		uint tempRemain = userList[sellerUid].remainAmount - amount;
		if(tempRemain<0){
			emit overSell(sellerUid);
			return;
		}
		userList[sellerUid].remainAmount =  tempRemain;
		userList[buyerUid].remainAmount +=  amount;
		emit queryBuyerAmount(userList[buyerUid].remainAmount);
		emit querySellerAmount(userList[sellerUid].remainAmount);
	}
	
}