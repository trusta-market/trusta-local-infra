# trusta-local-infra

Trusta Market **로컬 개발용 인프라** 통합 레포.

각 서비스가 로컬에서 개발할 때 필요한 공용 인프라(DB, Redis, Kafka 등)를 한 곳에서 관리합니다.

## 구성

| 인프라           | 포트   | 용도                 |
|---------------|------|--------------------|
| PostgreSQL 17 | 5432 | 7개 서비스가 스키마로 분리 사용 |

## 데이터베이스 구조

**단일 DB + 서비스별 스키마** 구조입니다.

PostgreSQL (trusta_market DB)
└── p_{service} 스키마  →  {service}_user

- 각 서비스는 **자기 전용 사용자**로만 접속
- 자기 스키마 외엔 **권한으로 접근 차단**
- 크로스 스키마 쿼리 금지 (MSA 원칙)

## 네이밍 규칙

| 구분 | 규칙 | 예시 |
|------|------|------|
| 스키마 | `p_{service}` | `p_inspection` |
| 사용자 | `{service}_user` | `inspection_user` |
| 비밀번호 | `{service}_pw` (로컬 전용) | `inspection_pw` |
| 테이블 | **단수형** | `inspection`, `inspection_center` |

> `p_` 접두사는 PostgreSQL 예약어(`user`, `order` 등) 충돌을 피하기 위함.

## 서비스 DB 접속 정보

현재 추가된 서비스만 표시. 각 서비스 담당자가 자기 차례에 스키마/사용자를 추가합니다.

| 서비스 | username | password | schema | 상태 |
|--------|----------|----------|--------|------|
| inspection | inspection_user | inspection_pw | p_inspection | ✅ |
| delivery | - | - | - | ⏳ |
| user | - | - | - | ⏳ |
| product | - | - | - | ⏳ |
| order | - | - | - | ⏳ |
| payment | - | - | - | ⏳ |
| wallet | - | - | - | ⏳ |

공통 접속 URL: `jdbc:postgresql://localhost:5432/trusta_market`

## 사용법

### 기동

```bash
docker-compose up -d
```

### 상태 확인

```bash
docker-compose ps
```

`healthy` 상태가 되면 준비 완료.


# Keycloak 로컬 개발 환경 설정 가이드
로컬 개발 환경에서 Keycloak을 사용하기 위한 설정 가이드입니다.

Gateway가 JWT 검증을 담당하고, 각 서비스는 Gateway가 변환한 X-User-* 헤더를 신뢰하는 구조입니다.
```
클라이언트
    ↓ JWT 토큰
Gateway (JWT 검증 → X-User-* 헤더 변환)
    ↓ X-User-* 헤더
각 서비스 (헤더만 신뢰, JWT 모름)
```

`docker-compose up -d` 하면 실행됩니다

Keycloak은 시작까지 약 30~40초 소요됩니다.

```
NAME                      STATUS
trusta-postgres           Up (healthy)
trusta-keycloak-postgres  Up (healthy)
trusta-keycloak           Up (healthy)
```
모든 서비스가 `healthy` 상태여야합니다
Docker Desktop을 사용한다면 Containers 탭에서 초록불로 확인할 수 있습니다

###  Keycloak 관리자 콘솔 접속
```
URL      : http://localhost:8080
아이디   : admin
비밀번호 : admin
```

접속 후 좌측 상단 Realm 선택 → **trusta** 선택

## 테스트 계정
> 아래 계정은 `docker-compose up -d` 시 **자동으로 생성**됩니다. 별도 설정 불필요.
> 
| 역할      | 이메일                | 비밀번호     |
|-----------|-----------------------|--------------|
| ADMIN     | admin@trusta.com      | admin123     |
| INSPECTOR | inspector@trusta.com  | inspector123 |
| MEMBER    | member@trusta.com     | member123    |
 
---

## 토큰 발급 방법

### Postman으로 발급 

```
Method : POST
URL    : http://localhost:8080/realms/trusta/protocol/openid-connect/token
Body   : x-www-form-urlencoded
 
grant_type    = password
client_id     = trusta-gateway
client_secret = gateway-secret-change-in-prod
username      = member@trusta.com
password      = member123
```

응답에서 `access_token` 값을 복사해서 API 호출 시 사용하세요.

```json
{
  "access_token": "eyJhbGci...",
  "refresh_token": "eyJhbGci...",
  "token_type": "Bearer",
  "expires_in": 300
}
```
### 혹시 postman 이 아니라 curl로 하시는분을위해 


```bash
curl -X POST http://localhost:8080/realms/trusta/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=trusta-gateway" \
  -d "client_secret=gateway-secret-change-in-prod" \
  -d "username=member@trusta.com" \
  -d "password=member123"
```
 
---

## Gateway 없이 단독 서비스 테스트



### application-local.yml 설정

```yaml
trusta:
  security:
    trust-gateway-headers: true
```

### Postman으로 테스트

```
Method  : GET
URL     : http://localhost:{서비스포트}/users/me
Headers :
  X-User-UUID     : 550e8400-e29b-41d4-a716-446655440000
  X-User-Email    : member@trusta.com
  X-User-Role     : ROLE_MEMBER
  X-User-Nickname : 테스트유저
  X-User-Enabled  : true
```

### 혹시 curl로 테스트 하는 분을위해

```bash
curl -X GET http://localhost:18081/users/me \
  -H "X-User-UUID: 550e8400-e29b-41d4-a716-446655440000" \
  -H "X-User-Email: member@trusta.com" \
  -H "X-User-Role: ROLE_MEMBER" \
  -H "X-User-Nickname: 테스트유저" \
  -H "X-User-Enabled: true"
```
 
---

## X-User-* 헤더 명세

Gateway가 JWT 검증 후 각 서비스로 전달하는 헤더 목록입니다.

| 헤더명          | 설명                       | 예시                                 |
|-----------------|----------------------------|--------------------------------------|
| X-User-UUID     | 유저 식별자 (Keycloak sub) | 550e8400-e29b-41d4-a716-446655440000 |
| X-User-Email    | 로그인 이메일              | member@trusta.com                    |
| X-User-Role     | Spring Security 권한       | ROLE_MEMBER                          |
| X-User-Nickname | 닉네임                     | 테스트유저                            |
| X-User-Enabled  | 계정 활성화 여부           | true                                 |
 
---

## 각 서비스 설정 방법

모든 서비스는 아래 두 가지만 설정하면 됩니다.

### 1. build.gradle 의존성 추가

```gradle
implementation 'com.trustamarket:common:0.0.1-SNAPSHOT'
```

### 2. application.yml 설정 추가

```yaml
trusta:
  security:
    trust-gateway-headers: true
```

> common 모듈의 LoginFilter가 X-User-* 헤더를 자동으로 SecurityContext에 주입하도록 설계되어있어서
> 각 서비스는 JWT나 Keycloak을 직접 알 필요가 없습니다.
 
---

## Realm 설정 정보

| 항목           | 값                            |
|----------------|-------------------------------|
| Realm 이름     | trusta                        |
| Client ID      | trusta-gateway                |
| Client Secret  | gateway-secret-change-in-prod |
| Access Token   | 5분                           |
| Refresh Token  | 30분                          |

> Client Secret은 로컬 개발용입니다. 운영 환경에서는 반드시 변경하셔야됩니다.

 방법 1. Keycloak 관리자 콘솔에서 직접 변경
 http://{운영 Keycloak 주소}
 - trusta Realm 선택
 - Clients → trusta-gateway
 - Credentials 탭
 - Regenerate 버튼 클릭
 - 새로운 Secret 복사

 방법 2. 환경변수로 관리 
운영 환경에서는 Secret을 코드에 직접 넣으면 안 되기때문에 
 환경변수나 Secret 관리 도구로 주입하셔야됩니다.

```yaml
# docker-compose.yml (운영용)
keycloak:
environment:
KC_CLIENT_SECRET: ${KEYCLOAK_CLIENT_SECRET}  ← 환경변수로 주입
bash# .env 파일 (운영 서버에만 존재, Git에 절대 올리면 안 됨)
KEYCLOAK_CLIENT_SECRET=실제_시크릿_값
```
---

## 자주 발생하는 문제

### Keycloak이 뜨지 않을 때

```bash
# 로그 확인
docker logs trusta-keycloak
 
# 컨테이너 재시작
docker-compose restart keycloak
```

`keycloak-postgres`가 `healthy` 상태인지 먼저 확인하세요. DB가 준비되지 않으면 Keycloak이 실행되지 않습니다.
 
---

### realm-export.json이 적용되지 않았을 때

최초 실행 시에만 import가 적용되서,. 이미 볼륨이 생성된 경우 볼륨을 삭제 후 재실행하셔야됩니다.

```bash
docker-compose down -v
docker-compose up -d
```

`-v` 옵션은 볼륨(DB 데이터)도 삭제해서. 로컬 개발 데이터가 초기화됩니다.
 
---

### 토큰 발급 시 401 오류가 날 때

Keycloak 관리자 콘솔에서 Client Secret을 확인하세요.

```
http://localhost:8080
→ trusta Realm 선택
→ Clients → trusta-gateway → Credentials 탭
→ Client Secret 값 확인
```
 
---

## 전체 종료

```bash
# 컨테이너만 종료 (데이터 유지)
docker-compose down
 
# 컨테이너 + 볼륨 전체 삭제 (데이터 초기화)
docker-compose down -v
```