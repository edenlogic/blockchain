// SPDX-License-Identifier: GLI-3.0
pragma solidity >= 0.8.0 < 0.9.0;

// 복불복 박스 게임 스마트 컨트랙트 정의
contract LuckyDrawBox {

    // 플레이어 정보를 담는 구조체
    struct Player {
        uint totalBalance;       // 누적 보상 금액
        bool isPlaying;          // 현재 게임 참여 여부
        bool hasShield;          // 무적권 보유 여부
        uint entryAmount;        // 입장 시 지불한 금액
    }

    // 박스 오픈 결과 정보를 담는 구조체
    struct BoxHistory {
        uint boxNumber;          // 오픈한 박스 번호
        string result;           // 결과 메시지
    }

    address public owner;                                       // 컨트랙트 소유자 주소
    mapping(address => Player) public players;                 // 주소별 플레이어 상태 저장
    mapping(address => BoxHistory[]) public histories;         // 주소별 박스 오픈 기록 저장
    mapping(address => uint) public pendingDeposits;           // 선입금 추적용 매핑

    uint public constant MIN_ENTRY_FEE = 0.001 ether;          // 최소 참가비 상수 정의

    event BoxOpened(address indexed player, uint boxNumber, string boxMeaning); // 박스 오픈 이벤트 정의

    constructor() { // 컨트랙트 배포 시 호출되는 생성자
        owner = msg.sender; // 배포자를 소유자로 설정
    }

    // 이더와 함께 바로 참가하는 함수
    function directJoin() public payable {
        require(msg.value >= MIN_ENTRY_FEE, "Entry fee too low"); // 참가비 검증
        require(!players[msg.sender].isPlaying, "Already in game"); // 중복 참가 방지

        uint fee = msg.value / 10; // 운영자 수수료 계산 (10%)
        payable(owner).transfer(fee); // 수수료 송금

        players[msg.sender] = Player({ // 참가자 정보 저장
            totalBalance: 0,
            isPlaying: true,
            hasShield: false,
            entryAmount: msg.value - fee
        });

        delete histories[msg.sender]; // 이전 기록 초기화
    }

    // 선입금한 이더로 수동 참가 처리
    function manualJoin() public {
        require(!players[msg.sender].isPlaying, "Already in game"); // 중복 참가 방지
        uint deposit = pendingDeposits[msg.sender]; // 선입금 확인
        require(deposit >= MIN_ENTRY_FEE, "Insufficient deposited amount"); // 최소금액 검증

        uint fee = deposit / 5; // 수수료 계산
        uint entry = deposit - fee; // 참가 기준 금액 계산
        require(entry > 0, "Net entry amount too low"); // 유효성 검사

        payable(owner).transfer(fee); // 수수료 송금
        pendingDeposits[msg.sender] = 0; // 선입금 기록 제거

        players[msg.sender] = Player({ // 참가 상태 등록
            totalBalance: 0,
            isPlaying: true,
            hasShield: false,
            entryAmount: entry
        });

        delete histories[msg.sender]; // 이전 기록 초기화
    }

    // 박스를 열고 보상/패널티 처리하는 함수
    function openBox() public {
        require(players[msg.sender].isPlaying, "You must join the game first"); // 참가 여부 확인
        require(players[msg.sender].entryAmount > 0, "Entry amount invalid"); // 금액 유효성 확인

        uint rand = getRandom() % 7; // 0~6 난수 생성
        uint base = players[msg.sender].entryAmount; // 입장 금액 기반 보상 기준
        string memory outcome; // 결과 메시지 변수

        if (rand == 0) { // 2 : 기본 보상 100%
            players[msg.sender].totalBalance += base; // 누적 보상에 입장 금액 추가
            outcome = "[0] +100% of entry: basic reward";
        } else if (rand == 1) { // 1 : 손해 -50%
            uint loss = base / 2;
            // 현재 보상에서 손해 금액만큼 차감하되, 음수가 되지 않게 처
            players[msg.sender].totalBalance = (players[msg.sender].totalBalance >= loss)
                ? players[msg.sender].totalBalance - loss
                : 0;
            outcome = "[1] -50% of entry: penalty";
        } else if (rand == 2) { // 2 :  큰 보상 200%
            players[msg.sender].totalBalance += base * 2; // 입장금액의 2배 보상 지급
            outcome = "[2] +200% of entry: big reward";
        } else if (rand == 3) { // 3 : 폭탄
            if (players[msg.sender].hasShield) { // 무적권이 있으면 막음
                players[msg.sender].hasShield = false; // 무적권 소멸
                outcome = "[3] bomb exploded: shield blocked";
            } else { // 무적권 없으면 게임 종료
                players[msg.sender].totalBalance = 0; // 보상 초기화
                players[msg.sender].isPlaying = false; // 게임 종료 처리
                outcome = "[3] bomb exploded: game over";
            }
        } else if (rand == 4) { // 4 : 보너스 턴 (아무 일 없음)
            outcome = "[4] bonus turn: nothing happens";
        } else if (rand == 5) { // 5 : 무적권 획득
            players[msg.sender].hasShield = true; // 무적권 활성화
            outcome = "[5] shield granted";
        } else if (rand == 6) { // 6 : 배수 보상
            uint multiplier = (getRandom() % 5) + 1; // 배수 (1~5배) 랜덤 결정
            uint reward = base * multiplier; // 보상 금액 계산
            players[msg.sender].totalBalance += reward; // 누적 보상 반영
            outcome = string(abi.encodePacked("[6] multiplier bonus: +", _uintToString(multiplier), "x of entry"));
        }
        // 히스토리에 결과 저장
        histories[msg.sender].push(BoxHistory(rand, outcome));
        // 이벤트 발생
        emit BoxOpened(msg.sender, rand, outcome);
    }

    // 게임 종료 및 보상 정산 함수
    function stopGame() public {
        require(players[msg.sender].isPlaying, "Not in game"); // 참여 여부 확인

        uint payout = players[msg.sender].totalBalance; // 보상 금액 저장
        // 플레이어 상태 초기
        players[msg.sender].totalBalance = 0; 
        players[msg.sender].isPlaying = false;
        players[msg.sender].hasShield = false;
        players[msg.sender].entryAmount = 0;

        if (payout > 0) { // 보상 송금 (0보다 클 경우에만)
            payable(msg.sender).transfer(payout); // 보상 송금
        }
    }

    // 내 보상 금액 반환
    function getMyBalance() public view returns (uint) {
        return players[msg.sender].totalBalance;
    }

    // 내 게임 상태 확인
    function isCurrentlyPlaying() public view returns (bool) {
        return players[msg.sender].isPlaying;
    }

    // 무적권 보유 여부 확인
    function hasShield() public view returns (bool) {
        return players[msg.sender].hasShield;
    }

    // 내 박스 히스토리 개수 확인
    function getMyBoxHistoryLength() public view returns (uint) {
        return histories[msg.sender].length;
    }

    // 내 박스 히스토리 중 특정 인덱스 조회
    function getMyBoxHistory(uint index) public view returns (uint, string memory) {
        require(index < histories[msg.sender].length, "Invalid index"); // 인덱스 유효성 검사
        BoxHistory memory item = histories[msg.sender][index]; // 해당 기록 가져오기
        return (item.boxNumber, item.result); // 박스 번호와 결과 반환
    }

    // 난수 생성 함수 (블록정보 기반)
    function getRandom() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number - 1))));
    }

    // uint를 문자열로 변환하는 유틸리티 함수
    function _uintToString(uint v) internal pure returns (string memory str) {
        if (v == 0) return "0";
        uint maxlength = 100;  // 최대 길이 설정
        bytes memory reversed = new bytes(maxlength); // 임시 버퍼 생성
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;  // 10으로 나눈 나머지 계산
            v = v / 10;  // 자리 수 이동
            reversed[i++] = bytes1(uint8(48 + remainder));  // 숫자를 문자로 변환
        }
        bytes memory s = new bytes(i); // 결과 버퍼 생성
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // 뒤집어서 복사
        }
        str = string(s); // 최종 문자열 반환
    }

    // 이더 입금 수신 시 기록하는 함수
    receive() external payable {
        pendingDeposits[msg.sender] += msg.value; // 입금액 누적 저장
    }
}
