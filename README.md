# Backend Portfolio Project

## 실행방법

로컬 개발은 **인프라(MySQL·Redis·Prometheus·Grafana)만 Docker 로 올리고, 앱은 `./gradlew bootRun` 으로 직접 기동**합니다.

```bash
# 1. Docker Desktop 실행
open -a Docker

# 2. 인프라 기동 (app 서비스는 profile 로 분리되어 있어 기본 up 에서 제외됨)
# --build: 변경된 .jar를 기준으로 새로운 컨테이너 빌드
docker compose up --build -d

# 3. MySQL 이 healthy 가 될 때까지 대기 (start_period 30s)
docker compose ps

# 4. 앱 기동
./gradlew bootRun
```

- 앱: http://localhost:8080
- Prometheus: http://localhost:9090 (앱 메트릭은 `host.docker.internal:8080` 으로 스크랩)
- Grafana: http://localhost:3001 (admin / admin)

앱까지 컨테이너로 띄우려면(배포 환경 재현) `full` 프로필을 켭니다. 이때는 8080 포트가 겹치므로 `bootRun` 을 같이 쓰지 마세요.

```bash
docker compose --profile full up -d --build
docker compose --profile full down       # 내릴 때도 --profile full 필요
```

## 실행 환경

테스트

- JDK 17
- Docker Desktop — 테스트가 Testcontainers 로 MySQL·Redis 컨테이너를 직접 띄웁니다. 
- Docker 가 켜져 있어야 `./gradlew build` 가 통과합니다.

## 트러블슈팅

### `./gradlew build` 가 Testcontainers 에러로 실패할 때

**증상** — 테스트 단계에서 컨테이너가 뜨지 않고 아래와 같은 메시지가 보입니다.

```
client version 1.32 is too old. Minimum supported API version is 1.44,
please upgrade your client to a newer version
```

**원인** — Docker Engine 29(Docker Desktop 4.5x 이상)부터 지원하는 최소 Docker API 버전이 `1.24` 에서 `1.44` 로 올라갔습니다. 구버전 Testcontainers 는 API `1.32` 로 접속을 시도하기 때문에 Docker 쪽에서 거절합니다. 강의 코드 문제가 아니라 의존성 버전 문제입니다.

**해결** — 이 저장소는 Testcontainers `1.21.4` 로 업데이트되어 있습니다. 예전에 클론해두셨다면 최신 코드를 받아주세요.

```bash
git pull origin main
./gradlew build --refresh-dependencies
```

직접 `build.gradle` 만 고치실 경우 세 줄의 버전만 올리면 됩니다. 소스 코드는 바뀌지 않습니다.

```gradle
testImplementation 'org.testcontainers:testcontainers:1.21.4'
testImplementation 'org.testcontainers:junit-jupiter:1.21.4'
testImplementation 'org.testcontainers:mysql:1.21.4'
```

**내 Docker 가 문제인지 확인하는 방법**

```bash
docker version --format '{{.Server.Version}} / min API {{.Server.MinAPIVersion}}'
```

`min API 1.44` 로 나오면 위 케이스입니다. `1.24` 로 나오면 다른 원인을 봐야 합니다.

**참고** — Testcontainers `2.0.x` 로 올려도 해결되지만, 2.0 부터는 아티팩트 이름(`testcontainers-mysql`)과 컨테이너 클래스 패키지가 바뀌어서 강의 코드와 달라집니다. 강의를 따라가는 중이라면 `1.21.4` 를 쓰세요. Docker Desktop 을 `28.5.2` 로 다운그레이드하는 우회도 가능하지만, 의존성 업데이트가 정석입니다.

# 인프라 구성법
terraform 을 통해 구성
1. **VPC, 서브넷, 보안 그룹 생성**
2. **EC2 인스턴스 및 SSH 키 등록**
3. **RDS(MySQL) 데이터베이스 생성 및 비밀번호 적용**
4. **CloudWatch 설정 및 모니터링 활성화**