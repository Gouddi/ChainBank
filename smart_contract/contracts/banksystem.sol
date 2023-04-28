pragma solidity ^0.8.11;
contract bank {
    uint curentacont=0;
    uint withdrawid=0;
    uint transferid=0;
    uint public balanc;
    AlarmClock private alarmClock;
    uint256 private lastUpdateTime;
    struct transferrequest{
        uint yeses;
        address sender;
        uint quantity ;
        mapping (address=>bool)who_approved;
        uint reciever;

    }

    
    struct withdrawrequest {
        
        uint approvals;
        address owner;
        uint howmuch;
        mapping (address=>bool)ownersapproved;
        
    }
    
    struct group{
        address[] owners;
        uint balance;
        mapping(uint =>withdrawrequest) withdrawrequests;
        mapping(uint =>transferrequest) transferrequests;
    }

    
    mapping(address=>uint) adr_to_groupid;
    mapping(uint=>group) groupid_to_group;
    mapping (address=>string) passwords;
    
    

    event withdrawrequested(address requester,uint amount,uint requestid,uint groupeid);
    event deposucess(uint amount,address depositor,uint grp);
    event acountcreated(address[] owners,uint theid);
    event withdrawconscent(address who_gave_consent ,uint req_id,uint countid);
    event withdrawsucess(uint acount_id,address withdrawer);
    event transfer_requested(uint moneyy,address asker,uint tranreqid,uint  count_id, uint recievers ) ;
    event transfer_conscent(address conscenter ,uint trreq_id,uint count__id);
    event transfer_sucess(uint acount__id,address transfrerer,uint _reciever);



    modifier enoughtbalance (uint __amount,uint id ){
        require(__amount<groupid_to_group[id].balance,"not enoight balance to withdraw");
        _;
    }

    modifier canwithdraw(address demander ,uint idgrp,uint id_demand){
        require(groupid_to_group[idgrp].withdrawrequests[id_demand].owner==demander,"you are not the owner of the request provided");
        require(groupid_to_group[idgrp].withdrawrequests[id_demand].approvals==groupid_to_group[idgrp].owners.length-1,"request not approved yet");
        _;
    }

    modifier canapprove(uint idacount,uint __reqid ){
        require(groupid_to_group[ idacount].withdrawrequests[__reqid].owner!=msg.sender,"you cant approve your own request");
        bool samira=false;
        for(uint i=0;i<groupid_to_group[idacount].owners.length;i++){
            if(groupid_to_group[ idacount].owners[i]==msg.sender){
                samira=true;
            }
            
        }
        require(samira,"you are not one of the owners you can't give conscent");
        
        require(groupid_to_group[ idacount].withdrawrequests[__reqid].ownersapproved[msg.sender]==false,"you already approved this request");
        require(__reqid<=withdrawid-1,"this request doesnt exist");
        _;
  
    }

    modifier valid_account( uint monji){
        require(monji<=curentacont-1,"the acount id is not v&alid");
        _;

    }

    modifier true_pass(string memory pass){
    require(keccak256(bytes(passwords[msg.sender])) == keccak256(bytes(pass)), "wrong password");
        _;
    }

    modifier enougth(uint _quantity,uint __id){
        require(_quantity<groupid_to_group[__id].balance,"not enought balance to teansfer ");
        _;
    }

    modifier cantransfer(address demanderr ,uint idgrpp,uint id__demand){
        require(groupid_to_group[idgrpp].transferrequests[id__demand].sender==demanderr,"you are not the owner of the transfer request provided");
        require(groupid_to_group[idgrpp].transferrequests[id__demand].yeses==groupid_to_group[idgrpp].owners.length-1,"transfer request not approved yet");
        _;
    }

    modifier can_give_conscent(uint _idacount,uint ___reqid ){
        require(groupid_to_group[ _idacount].transferrequests[___reqid].sender!=msg.sender,"you cant approve your own request");
        
        require(groupid_to_group[ _idacount].transferrequests[___reqid].who_approved[msg.sender]==false,"you already approved this request");
        require(___reqid<=transferid-1,"this request doesnt exist");
        _;
  
    }






    function generateRandomString(uint j) internal  view returns (string memory) {
    bytes memory charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    bytes memory randomString = new bytes(8);
    uint rand;
    for (uint i = 0; i < 8; i++) {
        rand = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, i,j)));
        randomString[i] = charset[rand % charset.length];
    }
    return string(randomString);
    }



    function create_acount(address [] memory  _owners   ) public {
        
        groupid_to_group[curentacont].owners=_owners;

        
        for (uint i=0;i<_owners.length ;i++){
            adr_to_groupid[_owners[i]]=curentacont;
            passwords[_owners[i]]=generateRandomString(i);
        }
        
        emit acountcreated(_owners,curentacont);
        curentacont++;

    }


    function get_password() public view returns (string memory ){
        return string(passwords[msg.sender]);
    }
    

    function deposit ()public payable{
        uint grpid =adr_to_groupid[msg.sender];
        groupid_to_group[grpid].balance+=msg.value;
        emit deposucess(msg.value,msg.sender,grpid);
        

    }
    
    


    function getbalance()public returns(uint) {
        uint grpp =adr_to_groupid[msg.sender];
        balanc=groupid_to_group[grpp].balance;
        
        return balanc;
    }


    function requestwitdraw(uint amout ,uint acountid,string memory mot_de_passe)public
     enoughtbalance(amout,acountid) 
     valid_account(acountid)
     true_pass(mot_de_passe){
       
        uint iddd=withdrawid;
        groupid_to_group[acountid].withdrawrequests[iddd].owner=msg.sender;
        groupid_to_group[acountid].withdrawrequests[iddd].howmuch=amout;
        
        emit withdrawrequested(msg.sender,amout,withdrawid,acountid);
        withdrawid++;
       
    }


    function give_conscent(uint reqid,uint grid,string memory _pass)public 
    canapprove(grid,reqid)
    true_pass(_pass){
        
        groupid_to_group[grid].withdrawrequests[reqid].approvals++;
        groupid_to_group[grid].withdrawrequests[reqid].ownersapproved[msg.sender]=true;
        emit withdrawconscent(msg.sender,reqid,grid);

    }


    function withdraw(uint acounid,uint demand_id, string memory  __pass) public 
    canwithdraw(msg.sender,acounid,demand_id)
    true_pass(__pass)  {
        uint256 _amount=groupid_to_group[acounid].withdrawrequests[demand_id].howmuch;
        (bool sent, )= payable(msg.sender).call{value:_amount}("");
        require(sent);
        groupid_to_group[acounid].balance-=_amount;
        delete groupid_to_group[acounid].withdrawrequests[demand_id];
        emit withdrawsucess(acounid,msg.sender);
    }


    function retreat  (uint __acount)public{
        uint pos;
        for(uint i=0;i<groupid_to_group[__acount].owners.length-1;i++){
                if(groupid_to_group[__acount].owners[i]==msg.sender){
                    pos=i;
                }

        }
        for(uint j=pos;j<groupid_to_group[__acount].owners.length-1;j++){
            groupid_to_group[__acount].owners[j]=groupid_to_group[__acount].owners[j+1];

        }
        groupid_to_group[__acount].owners.pop();


        
    }


    function requesttransfer(uint id_acount,uint money,string memory passWord,uint  recieveracount   )public 
    enougth(money,id_acount)
    true_pass(passWord){
        uint dd=transferid;
        groupid_to_group[id_acount].transferrequests[dd].sender=msg.sender;
        groupid_to_group[id_acount].transferrequests[dd].quantity=money;
        groupid_to_group[id_acount].transferrequests[dd].reciever=recieveracount;
        emit transfer_requested(money,msg.sender,dd,id_acount,recieveracount);
        transferid++;

    }


    function transferconscent(uint treq,uint _grid,string memory passswrd)public 
    can_give_conscent(_grid,treq)
    true_pass(passswrd){
        bool fathia=false;
        for(uint i=0;i<groupid_to_group[ _grid].owners.length;i++){
            if(groupid_to_group[ _grid].owners[i]==msg.sender){
                fathia=true;
            }
            
        }
        require(fathia ,"you are not one of the owners you can't give conscent for transfer");
        groupid_to_group[_grid].transferrequests[treq].yeses++;
        groupid_to_group[_grid].transferrequests[treq].who_approved[msg.sender]=true; 
        emit transfer_conscent(msg.sender,treq,_grid);
    }

    function transfer(uint __acounid,uint transid_id, string memory  passwd)public 
    cantransfer(msg.sender,__acounid,transid_id)
    true_pass(passwd){
        uint monjia =groupid_to_group[__acounid].transferrequests[transid_id].quantity;
        uint recueve_id=groupid_to_group[__acounid].transferrequests[transid_id].reciever;
        groupid_to_group[__acounid].balance-=monjia;
        groupid_to_group[recueve_id].balance+=monjia;

    }

    function increaseBalance() external {
    uint256 yearsSinceUpdate = (block.timestamp - lastUpdateTime) / YEAR_IN_SECONDS;
    if (yearsSinceUpdate > 0) {
        for (uint i = 0; i <= curentacont; i++) {
            Group storage group = groupIdToGroup[i];
            uint256 newBalance = group.balance * ((100 + 5 * yearsSinceUpdate) / 100);
            group.balance = newBalance;
        }
        lastUpdateTime = block.timestamp;
        scheduleIncreaseBalance();
    }
}

    function scheduleIncreaseBalance() private {
        scheduler.schedule(
            address(this),
            abi.encodeWithSignature("increaseBalance()"),
            block.timestamp + YEAR_IN_SECONDS
        );
    }

    // Other functions of the contract
}










    
