# LuckyBox (SmartContract Only)

Solidity로 구현한 블록체인 기반 랜덤박스 게임 스마트컨트랙트입니다.  
Remix IDE를 활용하여 게임 로직을 설계하고, 테스트넷(Sepolia)에 직접 배포하여 스마트컨트랙트 개발 역량을 쌓았습니다.

---

## 프로젝트 개요

- 사용자는 일정 금액을 지불하고 랜덤박스를 개봉합니다.
- 내부적으로 난수 기반 로직을 통해 당첨 여부가 결정됩니다.
- 관리자만 상자 보상 구성을 설정하거나 초기화할 수 있습니다.

---

## 주요 기능

### 사용자 함수
- `directJoin()`: 이더와 함께 즉시 게임 참가
- `manualJoin()`: 입금 후 수동 참가
- `openBox()`: 랜덤 박스를 열어 보상/위험/이벤트 발생
- `stopGame()`: 게임 종료 및 누적 보상 수령

### 상태 조회 함수
- `getMyStatus()`: 나의 게임 상태 전체 확인
- `getMyBalance()`: 누적 보상 금액 확인
- `isCurrentlyPlaying()`: 참가 중인지 여부 확인
- `hasShield()`: 무적권 보유 여부 확인
- `getMyBoxHistoryLength()`: 박스 오픈 기록 개수 확인
- `getMyBoxHistory(index)`: 개별 박스 오픈 결과 확인

### 기타 기능
- `receive()`: 외부에서 이더 입금 가능

---

## 디렉토리 구조

- contracts/ # LuckyBox.sol 스마트컨트랙트 코드
- scripts/ # 배포 스크립트
- tests/ # 테스트 코드
- README.md # 프로젝트 설명서
- .prettierrc # 코드 포맷 설정


---

## 사용 기술

- Solidity (0.8.x)
- Remix IDE
- Sepolia 테스트넷 (Ethereum)
- (선택) Hardhat, Ethers.js 등

---

## 스마트컨트랙트 주소

> **배포 주소:** `0x1234...abcd` *(예시: 네가 Sepolia에 배포한 주소 입력)*  
> **테스트넷:** Sepolia (Ethereum)

---

## 실행 방법 (Remix 기준)

1. [Remix IDE](https://remix.ethereum.org) 접속
2. `LuckyBox.sol` 파일 열기
3. Compile → Deploy
4. 버튼을 눌러 각 함수 실행 (Metamask 필요)

---

## 라이선스

MIT

---

