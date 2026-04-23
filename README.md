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
