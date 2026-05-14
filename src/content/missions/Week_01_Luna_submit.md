### 결과물

GitHub PR이 올라오면 자동으로 코드 리뷰를 해주는 봇을 만들었다. Cursor의 Rules 기능 + Claude API를 조합해서, PR diff를 읽고 보안 취약점, 성능 이슈, 코드 스타일 위반을 잡아주는 시스템.

- 배포: GitHub Actions로 PR 이벤트 트리거 (팀 레포에 적용 중)
- 기술 스택: GitHub Actions + Claude API + Python 스크립트

### 만든 과정 및 삽질

- 처음 접근: GitHub Actions에서 PR diff를 통째로 Claude API에 넘기려 했으나, diff가 큰 PR은 토큰 한도 초과. 파일별로 나눠서 호출하는 방식으로 변경
- Cursor의 `.cursorrules` 파일에 "이 프로젝트의 코딩 컨벤션" 규칙을 정리해두니, 같은 규칙을 Claude API 프롬프트에도 재사용할 수 있었음
- 리뷰 결과를 PR 코멘트로 남기는 부분에서 GitHub API rate limit에 걸림. 파일당 1개 코멘트 → PR당 1개 종합 코멘트로 변경해서 해결
- 오탐(false positive)이 초기에 많았음. "이 패턴은 의도적입니다" 같은 인라인 주석을 무시하는 로직 추가

### 인사이트

- AI 코드 리뷰의 가치는 "버그를 찾는 것"보다 "사람 리뷰어의 시간을 절약하는 것"에 있음. 명백한 스타일 위반, 미사용 import, 오타 등을 AI가 걸러주면 사람은 설계와 로직에 집중할 수 있음
- 프롬프트에 "확실하지 않으면 지적하지 마라"를 넣는 것만으로 오탐률이 60% 감소
- Cursor Rules와 Claude API 프롬프트를 통일하면 "로컬 개발 시 에디터 가이드 + PR 시 자동 검증"이 일관되게 동작함

### 다시 한다면?

- 리뷰 결과에 심각도(critical/warning/info)를 분류해서, critical만 PR 블로킹하는 구조로 만들고 싶음
- 팀 전체의 과거 리뷰 코멘트를 학습 데이터로 넣으면 팀 고유의 리뷰 패턴을 반영할 수 있을 듯
