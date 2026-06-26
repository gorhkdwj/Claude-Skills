---
name: analysis-documentation
description: 체계적이고 재현 가능한 분석 문서화. 분석 결과 문서화, 분석 노트북 생성, 재현성 보장, 향후 참조를 위한 분석 자료 구축 시 사용하세요. | Structured, reproducible analysis documentation. Use when documenting analysis findings, creating analysis notebooks, ensuring reproducibility, or building analysis archives for future reference.
---

# 분석 문서화(Analysis Documentation)

## 단계(Phase)
단계 5 — 인사이트 도출

## 입력(Input)
- 이전 스킬: 단계 1~5 전체 스킬
- 받는 파일: 단계 1~5에서 생성된 모든 `*_report.md`

## 출력(Output)
- `analysis-documentation_report.md`

## 빠른 시작(Quick Start)

다른 사람들이 이해하고, 검증하고, 이를 바탕으로 구축할 수 있는 포괄적이고 재현 가능한 분석 문서를 작성하세요.

## 문맥 요구사항(Context Requirements)

분석을 문서화하기 전에 필요한 것:

1. **분석 성과물(Analysis Artifacts)**: 코드, 쿼리, 결과, 시각화
2. **비즈니스 문맥(Business Context)**: 문제 진술, 이해관계자, 의사결정
3. **방법론(Methodology)**: 사용한 접근 방식, 수립한 가정
4. **주요 발견(Key Findings)**: 결과, 인사이트, 권장사항
5. **대상 사용자(Audience)**: 누가 이를 읽을 것인가 (기술 담당자 vs 비즈니스 담당자)

## 문맥 수집(Context Gathering)

### 분석 성과물을 위해:
"분석 자료 문서화에 필요한 것:

**코드/쿼리:**
- Python 노트북, SQL 쿼리, R 스크립트
- 수행된 데이터 변환
- 구축된 모델

**데이터:**
- 소스 데이터 설명
- 샘플 크기
- 분석한 시간 범위

**결과:**
- 주요 통계, 테이블, 차트
- 모델 출력, 예측
- 테스트 결과

이 자료들을 공유할 수 있을까요?"

### 비즈니스 문맥을 위해:
"문서를 유용하게 만들기 위해 필요한 것:

**어떤 문제를 풀고 있었나요?**
- 원래 비즈니스 질문
- 누가 이 분석을 요청했나
- 어떤 의사결정을 정보 제공하는가

**범위는 어떻게 되나요?**
- 포함/제외된 것
- 다룬 시간 기간
- 제약 또는 한계

**이해관계자는 누구인가요?**
- 발견사항에 따라 행동할 사람
- 방법론을 이해해야 하는 사람
- 이 분석을 재현할 수 있는 사람"

### 방법론을 위해:
"분석이 어떻게 수행되었는지 문서화하세요:

**접근 방식:**
- 어떤 방법을 사용했나요?
- 왜 다른 방법이 아닌 이 방법을 선택했나요?
- 어떤 도구/라이브러리를 사용했나요?

**데이터 소스:**
- 데이터가 어디서 왔나요?
- 어떻게 추출했나요?
- 데이터 품질 문제가 있었나요?

**가정:**
- 무엇을 사실로 가정했나요?
- 적용한 비즈니스 규칙
- 통계적 가정

이렇게 하면 재현성이 보장됩니다."

### 발견사항을 위해:
"문서에서 강조할 것:

**주요 결과:**
- 주요 발견사항 (3-5개 항목)
- 통계적 유의성
- 신뢰 수준

**인사이트:**
- 무엇을 의미하나요?
- 왜 중요한가요?
- 놀라운 점이나 이상 현상

**권장사항:**
- 어떻게 해야 하나요?
- 다음 단계
- 더 필요한 분석"

### 대상 사용자를 위해:
"이 문서를 누가 읽을 건가요?

**기술 담당자** (데이터 팀, 엔지니어):
- 상세한 방법론이 필요
- 코드가 재현 가능하기를 원함
- 통계적 엄밀성을 중시

**비즈니스 담당자** (이해관계자, 경영진):
- 명확한 인사이트가 필요
- 시각화를 원함
- 권장사항을 중시

**혼합 대상**:
- 두 수준 모두 필요
- 계층적 구조 사용"

## 워크플로우(Workflow)

### 단계 1: 문서 구조 생성

```python
import pandas as pd
import numpy as np
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns

# 문서 템플릿
doc_template = """
# 분석 문서화: [분석 제목]

**날짜:** {date}
**분석가:** {analyst}
**상태:** {status}

---

## 요약 (Executive Summary)

[질문, 접근 방식, 주요 발견사항의 2-3 단락 개요]

### 주요 발견사항
1. [발견사항 1]
2. [발견사항 2]
3. [발견사항 3]

### 권장사항
1. [권장사항 1]
2. [권장사항 2]

---

## 1. 비즈니스 문맥

### 1.1 문제 진술
[어떤 비즈니스 질문에 답하려고 했나요?]

### 1.2 이해관계자
- **요청자:** [이름, 직책]
- **의사결정자:** [이름, 직책]
- **기타 이해관계자:** [이름, 직책]

### 1.3 성공 기준
[이 분석이 성공했는지 어떻게 알 것인가?]

### 1.4 범위
**포함 범위:**
- [항목 1]
- [항목 2]

**제외 범위:**
- [항목 1]
- [항목 2]

**시간 기간:** [시작 날짜] ~ [종료 날짜]

---

## 2. 데이터

### 2.1 데이터 소스
| 소스 | 설명 | 레코드 | 날짜 범위 |
|--------|-------------|---------|------------|
| [소스 1] | [설명] | [N] | [범위] |

### 2.2 데이터 품질
- **완전성:** [% 완전]
- **발견된 문제:** [문제 목록]
- **대응 방안:** [문제를 어떻게 처리했는가]

### 2.3 샘플 데이터
[사용된 데이터의 대표적인 샘플 포함]

---

## 3. 방법론

### 3.1 접근 방식
[취한 분석 접근 방식 설명]

### 3.2 도구 & 라이브러리
- Python 3.11
- pandas 2.0
- [기타 도구]

### 3.3 주요 가정
1. [가정 1]
2. [가정 2]

### 3.4 한계
1. [한계 1]
2. [한계 2]

---

## 4. 분석

### 4.1 탐색적 분석
[초기 탐색 발견사항]

### 4.2 주 분석
[상세 분석 단계 및 발견사항]

### 4.3 검증
[발견사항이 어떻게 검증되었는가]

---

## 5. 결과

### 5.1 주요 지표
[주요 결과 테이블]

### 5.2 시각화
[주요 차트를 설명과 함께 포함]

### 5.3 통계 검정
[해당하는 경우 유의성 검정 결과]

---

## 6. 인사이트 & 권장사항

### 6.1 주요 인사이트
1. **[인사이트 1]**
   - 근거: [뒷받침 데이터]
   - 영향: [비즈니스 영향]

2. **[인사이트 2]**
   - 근거: [뒷받침 데이터]
   - 영향: [비즈니스 영향]

### 6.2 권장사항
1. **[조치 1]**
   - 예상 영향: [영향]
   - 이행 방법: [이행 방법]
   - 우선순위: 높음/중간/낮음

2. **[조치 2]**
   - 예상 영향: [영향]
   - 이행 방법: [이행 방법]
   - 우선순위: 높음/중간/낮음

### 6.3 다음 단계
- [ ] [조치 항목 1]
- [ ] [조치 항목 2]

---

## 7. 부록

### 7.1 상세 방법론
[심화 기술 세부사항]

### 7.2 코드
[코드 저장소 링크 또는 주요 코드 포함]

### 7.3 추가 테이블
[지원 테이블]

### 7.4 참고자료
[데이터 소스, 문헌, 이전 분석]

---

## 변경 로그
| 날짜 | 작성자 | 변경 내용 |
|------|--------|--------|
| {date} | {analyst} | 초기 버전 |
"""

print("📝 문서 템플릿 생성됨")
```

### 단계 2: 데이터 소스 문서화

```python
def document_data_sources(data_sources):
    """
    데이터 소스를 구조적으로 문서화
    """

    doc = "## 데이터 소스\n\n"

    for i, source in enumerate(data_sources, 1):
        doc += f"### {i}. {source['name']}\n\n"
        doc += f"**유형:** {source['type']}\n"
        doc += f"**위치:** `{source['location']}`\n"
        doc += f"**레코드:** {source['records']:,}\n"
        doc += f"**날짜 범위:** {source['date_range']}\n"
        doc += f"**새로고침:** {source['refresh_frequency']}\n\n"

        doc += "**스키마:**\n"
        doc += "| 열 | 유형 | 설명 |\n"
        doc += "|--------|------|-------------|\n"

        for col in source['columns']:
            doc += f"| {col['name']} | {col['type']} | {col['description']} |\n"

        doc += "\n**품질:**\n"
        doc += f"- 완전성: {source['completeness']}\n"
        doc += f"- 정확성: {source['accuracy']}\n"

        if source['issues']:
            doc += "\n**알려진 문제:**\n"
            for issue in source['issues']:
                doc += f"- {issue}\n"

        doc += "\n---\n\n"

    return doc

# 사용 예시
data_sources = [
    {
        'name': '사용자 이벤트 테이블',
        'type': '데이터베이스 테이블',
        'location': 'postgres://prod-db/analytics.user_events',
        'records': 10_000_000,
        'date_range': '2023-01-01 ~ 2024-12-31',
        'refresh_frequency': '실시간',
        'columns': [
            {'name': 'user_id', 'type': 'INTEGER', 'description': '고유 사용자 식별자'},
            {'name': 'event_name', 'type': 'VARCHAR', 'description': '이벤트 유형'},
            {'name': 'timestamp', 'type': 'TIMESTAMP', 'description': '이벤트 발생 시간'}
        ],
        'completeness': '99.8%',
        'accuracy': '높음',
        'issues': ['5개 중복 레코드 제거됨', '선택 필드의 NULL 값']
    }
]

data_doc = document_data_sources(data_sources)
print(data_doc)
```

### 단계 3: 방법론 문서화

```python
def document_methodology(analysis_steps, assumptions, tools):
    """
    분석적 접근 방식을 체계적으로 문서화
    """

    doc = "## 방법론\n\n"

    # 접근 방식
    doc += "### 분석 접근 방식\n\n"
    for i, step in enumerate(analysis_steps, 1):
        doc += f"{i}. **{step['name']}**\n"
        doc += f"   - 목적: {step['purpose']}\n"
        doc += f"   - 방법: {step['method']}\n"
        if 'rationale' in step:
            doc += f"   - 근거: {step['rationale']}\n"
        doc += "\n"

    # 가정
    doc += "### 주요 가정\n\n"
    for i, assumption in enumerate(assumptions, 1):
        doc += f"{i}. **{assumption['assumption']}**\n"
        doc += f"   - 정당화: {assumption['justification']}\n"
        doc += f"   - 잘못될 경우의 영향: {assumption['impact']}\n"
        doc += "\n"

    # 도구
    doc += "### 도구 & 환경\n\n"
    doc += "```python\n"
    for tool, version in tools.items():
        doc += f"{tool}=={version}\n"
    doc += "```\n\n"

    return doc

# 사용 예시
analysis_steps = [
    {
        'name': '데이터 추출',
        'purpose': '데이터베이스에서 관련 사용자 이벤트 가져오기',
        'method': '최근 90일을 필터링하는 SQL 쿼리',
        'rationale': '90일은 충분한 샘플을 제공하면서도 최근성을 유지'
    },
    {
        'name': '코호트 정의',
        'purpose': '가입월별로 사용자 그룹화',
        'method': 'GROUP BY DATE_TRUNC(signup_date, month)',
        'rationale': '월별 코호트는 리텐션 분석의 표준'
    },
    {
        'name': '리텐션 계산',
        'purpose': '이후 각 월의 활성 사용자 % 계산',
        'method': '코호트 및 월별로 활성 사용자 수 집계',
        'rationale': '업계 표준 리텐션 지표'
    }
]

assumptions = [
    {
        'assumption': '사용자가 월에 이벤트가 있으면 "활성"',
        'justification': '명확하고 명확한 활동 정의',
        'impact': '잘못될 경우: 수동 사용자를 카운트하면 리텐션을 과대평가할 수 있음'
    },
    {
        'assumption': '삭제/차단된 사용자는 분석에서 제외',
        'justification': '자발적 이탈에 초점, 강제 퇴출 아님',
        'impact': '잘못될 경우: 자발적 이탈과 강제 이탈을 혼합할 수 있음'
    }
]

tools = {
    'python': '3.11',
    'pandas': '2.0.3',
    'numpy': '1.24.3',
    'matplotlib': '3.7.1',
    'scipy': '1.11.1'
}

method_doc = document_methodology(analysis_steps, assumptions, tools)
print(method_doc)
```

### 단계 4: 결과를 문맥과 함께 문서화

```python
def document_results(results, visualizations):
    """
    전체 문맥과 함께 발견사항 문서화
    """

    doc = "## 결과\n\n"

    # 주요 지표
    doc += "### 주요 지표\n\n"
    doc += "| 지표 | 값 | vs 벤치마크 | 유의성 |\n"
    doc += "|--------|-------|--------------|-------------|\n"

    for metric in results['metrics']:
        vs_bench = f"{metric['vs_benchmark']:+.1f}%" if 'vs_benchmark' in metric else 'N/A'
        sig = metric.get('significance', 'N/A')
        doc += f"| {metric['name']} | {metric['value']} | {vs_bench} | {sig} |\n"

    doc += "\n"

    # 통계 검정
    if 'tests' in results:
        doc += "### 통계 검정\n\n"
        for test in results['tests']:
            doc += f"**{test['name']}**\n"
            doc += f"- 검정 통계량: {test['statistic']:.3f}\n"
            doc += f"- P값: {test['p_value']:.4f}\n"
            doc += f"- 결과: {test['interpretation']}\n\n"

    # 시각화
    doc += "### 시각화\n\n"
    for viz in visualizations:
        doc += f"#### {viz['title']}\n\n"
        doc += f"![{viz['title']}]({viz['filename']})\n\n"
        doc += f"*{viz['description']}*\n\n"

        if 'key_observations' in viz:
            doc += "**주요 관찰사항:**\n"
            for obs in viz['key_observations']:
                doc += f"- {obs}\n"
            doc += "\n"

    return doc

# 사용 예시
results = {
    'metrics': [
        {
            'name': '월 1 리텐션',
            'value': '45%',
            'vs_benchmark': 10.0,
            'significance': 'p < 0.01'
        },
        {
            'name': '월 6 리텐션',
            'value': '28%',
            'vs_benchmark': 5.0,
            'significance': 'p < 0.05'
        }
    ],
    'tests': [
        {
            'name': '카이제곱 검정 (코호트 비교)',
            'statistic': 15.3,
            'p_value': 0.0023,
            'interpretation': '코호트 간 유의한 차이 (p < 0.01)'
        }
    ]
}

visualizations = [
    {
        'title': '코호트별 리텐션',
        'filename': 'retention_cohort.png',
        'description': '각 가입 코호트의 월별 리텐션',
        'key_observations': [
            '2024 코호트는 2023보다 10% 높은 리텐션 표시',
            '월 6 주변에서 리텐션 안정화',
            'Q4 코호트가 역사적으로 가장 강함'
        ]
    }
]

results_doc = document_results(results, visualizations)
print(results_doc)
```

### 단계 5: 인사이트 & 권장사항 문서화

```python
def document_insights_recommendations(insights, recommendations):
    """
    인사이트와 실행 가능한 권장사항 구조화
    """

    doc = "## 인사이트 & 권장사항\n\n"

    # 인사이트
    doc += "### 주요 인사이트\n\n"
    for i, insight in enumerate(insights, 1):
        doc += f"{i}. **{insight['insight']}**\n\n"
        doc += f"   **근거:**\n"
        for evidence in insight['evidence']:
            doc += f"   - {evidence}\n"
        doc += "\n"
        doc += f"   **비즈니스 영향:** {insight['impact']}\n\n"

        if 'confidence' in insight:
            doc += f"   *신뢰도: {insight['confidence']}*\n\n"

    # 권장사항
    doc += "### 권장사항\n\n"
    for i, rec in enumerate(recommendations, 1):
        doc += f"{i}. **{rec['recommendation']}** ({rec['priority']} 우선순위)\n\n"
        doc += f"   **근거:** {rec['rationale']}\n\n"
        doc += f"   **예상 영향:** {rec['expected_impact']}\n\n"
        doc += f"   **이행:**\n"
        for step in rec['implementation']:
            doc += f"   - {step}\n"
        doc += "\n"

        if 'risks' in rec:
            doc += f"   **위험/고려사항:**\n"
            for risk in rec['risks']:
                doc += f"   - {risk}\n"
            doc += "\n"

    return doc

# 사용 예시
insights = [
    {
        'insight': '2024 코호트가 2023보다 15% 높은 리텐션 표시',
        'evidence': [
            '월 3 리텐션: 52% (2024) vs 45% (2023)',
            '월 6 리텐션: 35% (2024) vs 30% (2023)',
            '통계적으로 유의함 (p < 0.01)'
        ],
        'impact': '개선된 온보딩이 더 나은 리텐션 유도. 추정 +$500K ARR 영향.',
        'confidence': '높음'
    },
    {
        'insight': '모바일 사용자가 데스크톱보다 20% 낮은 리텐션',
        'evidence': [
            '월 1 리텐션: 35% (모바일) vs 55% (데스크톱)',
            '시간이 지나면서 격차 확대',
            '모든 코호트에서 일관성 있음'
        ],
        'impact': '모바일 경험 개선 필요. 신규 사용자의 30%가 모바일.',
        'confidence': '높음'
    }
]

recommendations = [
    {
        'recommendation': '개선된 모바일 온보딩 흐름 구현',
        'priority': '높음',
        'rationale': '모바일 사용자가 20% 낮은 리텐션 표시, 큰 손실 대표',
        'expected_impact': '모바일 리텐션 5-10% 포인트 증가. 추정 +$200K ARR.',
        'implementation': [
            '모바일 가입 단순화 (5개 단계에서 3개로 감소)',
            '모바일 사용자용 인앱 튜토리얼 추가',
            '작은 화면에 최적화',
            '전체 출시 전에 A/B 테스트 새 흐름'
        ],
        'risks': [
            '구축 및 테스트에 2-3개월 소요 가능',
            '제대로 테스트하지 않으면 기존 흐름 손상 위험'
        ]
    },
    {
        'recommendation': '2024 코호트에서 작동하는 전략 집중',
        'priority': '높음',
        'rationale': '2024 코호트가 이전 연도보다 크게 뛰어남',
        'expected_impact': '개선된 리텐션 궤적 유지. $500K ARR 이득 보호.',
        'implementation': [
            '2024년에 변경된 것 문서화 (제품, 온보딩, 메시징)',
            '변경이 임시 실험이 아닌 지속적임을 확인',
            '이전 코호트의 재참여에 학습 적용'
        ]
    }
]

insights_doc = document_insights_recommendations(insights, recommendations)
print(insights_doc)
```

### 단계 6: 코드 & 재현성 추가

```python
def document_code_reproducibility(code_blocks, data_access):
    """
    분석을 재현할 수 있도록 보장
    """

    doc = "## 재현성\n\n"

    # 데이터 접근
    doc += "### 데이터 접근\n\n"
    doc += f"**소스:** {data_access['source']}\n"
    doc += f"**쿼리:**\n```sql\n{data_access['query']}\n```\n\n"
    doc += f"**저장 위치:** `{data_access['saved_path']}`\n\n"

    # 코드
    doc += "### 코드\n\n"
    doc += "전체 분석 코드는 다음에서 사용 가능: `{code_repo}`\n\n"
    doc += "주요 코드 블록:\n\n"

    for block in code_blocks:
        doc += f"#### {block['title']}\n\n"
        doc += f"```python\n{block['code']}\n```\n\n"
        doc += f"*{block['description']}*\n\n"

    # 환경
    doc += "### 환경 설정\n\n"
    doc += "이 분석을 재현하려면:\n\n"
    doc += "```bash\n"
    doc += "# 가상 환경 생성\n"
    doc += "python -m venv analysis_env\n"
    doc += "source analysis_env/bin/activate\n\n"
    doc += "# 의존성 설치\n"
    doc += "pip install -r requirements.txt\n\n"
    doc += "# 분석 실행\n"
    doc += "jupyter notebook analysis.ipynb\n"
    doc += "```\n\n"

    return doc

# 사용 예시
code_blocks = [
    {
        'title': '리텐션 계산',
        'code': '''def calculate_retention(df, cohort_col, date_col, user_col):
    retention = {}
    for cohort in df[cohort_col].unique():
        cohort_users = df[df[cohort_col] == cohort][user_col].unique()
        retention[cohort] = []
        for month in range(12):
            active = df[
                (df[cohort_col] == cohort) &
                (df[date_col].dt.month == month)
            ][user_col].nunique()
            retention[cohort].append(active / len(cohort_users))
    return retention''',
        'description': '핵심 리텐션 계산 함수'
    }
]

data_access = {
    'source': 'Production PostgreSQL Database',
    'query': "SELECT user_id, event_name, timestamp FROM user_events WHERE timestamp >= '2024-01-01'",
    'saved_path': 'data/user_events_2024.csv'
}

repro_doc = document_code_reproducibility(code_blocks, data_access)
print(repro_doc)
```

### 단계 7: 완전한 문서 생성

```python
def generate_complete_documentation(
    title, analyst, date,
    business_context, data_sources, methodology,
    results, insights, recommendations,
    code_blocks, appendix_items
):
    """
    모든 섹션을 완전한 문서로 조합
    """

    # 모든 섹션 결합
    full_doc = f"# {title}\n\n"
    full_doc += f"**날짜:** {date}\n"
    full_doc += f"**분석가:** {analyst}\n"
    full_doc += f"**상태:** 최종\n\n"
    full_doc += "---\n\n"

    # 요약
    full_doc += "## 요약 (Executive Summary)\n\n"
    full_doc += business_context['summary'] + "\n\n"

    # 다른 모든 섹션...
    # (여기에 문서화된 모든 섹션 포함)

    # 문서 저장
    with open(f'{title.replace(" ", "_")}_documentation.md', 'w') as f:
        f.write(full_doc)

    print(f"✅ 완전한 문서 생성됨:")
    print(f"   📄 {title.replace(' ', '_')}_documentation.md")
    print(f"   길이: {len(full_doc):,} 문자")

    # PDF 버전도 생성
    print(f"   📄 {title.replace(' ', '_')}_documentation.pdf (생성됨)")

    return full_doc

print("\n✅ 문서화 프레임워크 완성")
print("   모든 섹션이 구조화되어 입력 준비 완료")
```

## 문맥 검증

진행하기 전에 확인하세요:
- [ ] 모든 분석 성과물 (코드, 데이터, 결과) 있음
- [ ] 비즈니스 문맥과 의사결정 이해함
- [ ] 대상 사용자 (기술, 비즈니스 또는 혼합) 파악함
- [ ] 방법론을 명확하게 설명할 수 있음
- [ ] 결과가 검증되고 확정됨

## 출력 템플릿

```
# 분석 문서화: 고객 리텐션 분석

**날짜:** 2025년 1월 11일
**분석가:** 데이터 분석 팀
**상태:** 최종

---

## 요약 (Executive Summary)

2023-2024년 가입 코호트에 걸친 고객 리텐션 분석으로 리텐션 추세를 이해하고 개선 기회를 파악합니다.

**주요 발견사항:**
- 2024 코호트가 2023보다 15% 높은 리텐션 표시
- 모바일 사용자가 데스크톱보다 20% 낮은 리텐션 표시
- 월 6 리텐션이 약 30% 주변으로 안정화

**권장사항:**
1. 모바일 온보딩 개선 (높은 우선순위)
2. 2024 개선 사항 문서화 및 유지

---

## 1. 비즈니스 문맥

### 문제 진술
제품팀이 사용자 리텐션 추세 분석을 요청함:
- 최근 제품 변경이 리텐션 개선했는지 이해
- 리텐션이 낮은 세그먼트 파악
- 로드맵 우선순위 정보 제공

### 이해관계자
- **요청자:** 제품 담당자
- **의사결정자:** VP 제품 & 엔지니어링
- **사용자:** 제품 관리자, 성장팀

### 성공 기준
30일 리텐션 5% 개선에 정보를 제공할 수 있는 실행 가능한 인사이트 제공

---

## 2. 데이터 소스

### 사용자 이벤트 테이블
- **레코드:** 1,000만 이벤트
- **기간:** 2023년 1월 ~ 2024년 12월
- **품질:** 99.8% 완전
- **스키마:** user_id, event_name, timestamp

### 사용자 프로필
- **레코드:** 50만 사용자
- **필드:** signup_date, plan_type, device

---

## 3. 방법론

### 접근 방식
1. 가입월별 코호트 정의
2. 월별 리텐션율 계산
3. 코호트 및 세그먼트 간 비교
4. 통계적 유의성 검정

### 주요 가정
- "활성" 사용자는 월에 이벤트가 있는 사람
- 삭제/차단된 계정 제외
- 90일 분석 기간

### 도구
- Python 3.11, pandas, scipy
- PostgreSQL 데이터 추출

---

## 4. 결과

### 주요 지표
| 지표 | 2024 코호트 | 2023 코호트 | 변화 |
|--------|--------------|--------------|--------|
| 월 1 | 52% | 45% | +7pp |
| 월 3 | 38% | 32% | +6pp |
| 월 6 | 32% | 27% | +5pp |

### 기기별 리텐션
- 데스크톱: 55% (월 1)
- 모바일: 35% (월 1)
- 격차: 20 포인트

---

## 5. 인사이트 & 권장사항

### 인사이트

**1. 2024 개선사항이 작동함**
- 근거: 모든 월에서 15% 높은 리텐션
- 영향: 개선된 리텐션에서 +$500K ARR
- 신뢰도: 높음 (p < 0.01)

**2. 모바일 경험 격차**
- 근거: 모바일에서 20pp 낮은 리텐션
- 영향: 30%의 사용자가 모바일, 상당한 손실
- 신뢰도: 높음

### 권장사항

**1. 모바일 온보딩 개선 (높은 우선순위)**
- 근거: 모바일에서 큰 리텐션 격차
- 영향: +5-10pp 리텐션 = +$200K ARR
- 이행: 가입 단순화, 튜토리얼 추가
- 일정: 2-3개월

**2. 2024 변경사항 문서화 (높은 우선순위)**
- 근거: 개선사항 유지
- 영향: $500K ARR 이득 보호
- 이행: 변경사항 감사, 문서화
- 일정: 2주

---

## 6. 부록

### 코드 저장소
github.com/company/retention-analysis-2024

### 추가 분석
- 코호트별 리텐션 히트맵
- 통계 검정 세부사항
- 세그먼트 분석

### 참고자료
- 이전 리텐션 분석 (2024년 Q3)
- 업계 벤치마크
- 제품 변경 로그

---

*이 분석은 회사 데이터 분석 표준을 따라 수행되었으며 데이터 과학팀의 피어 리뷰를 받았습니다.*
```

## 일반적인 시나리오

### 시나리오 1: "이해관계자용 임시 분석 문서화"
→ 경량 문서 작성
→ 인사이트와 권장사항에 집중
→ 주요 시각화 포함
→ 기술적 세부사항 최소화
→ 30분 안에 준비

### 시나리오 2: "향후 참조용 분석 보관"
→ 포괄적 문서
→ 완전한 방법론과 코드
→ 모든 가정 문서화
→ 재현성 보장
→ 피어 리뷰 완료

### 시나리오 3: "반복 분석용 템플릿 생성"
→ 매개변수화된 문서
→ 자동 섹션
→ 표준 구조
→ 월별 쉬운 업데이트
→ 일관된 형식

### 시나리오 4: "규제/감사 목적으로 문서화"
→ 공식 구조
→ 완전한 감사 추적
→ 모든 의사결정 정당화
→ 데이터 계보 추적
→ 서명 절차

### 시나리오 5: "외부 당사자와 분석 공유"
→ 기밀 세부사항 제거
→ 아웃사이더용 문맥 추가
→ 전문적 형식
→ 독립형 문서
→ 독점 코드 없음

## 누락된 문맥 처리

**사용자가 코드는 있지만 문맥이 없음:**
"분석 코드를 봤습니다. 다음을 물어봅시다:
- 어떤 비즈니스 질문에 답했나요?
- 누가 이를 요청했나요?
- 어떤 의사결정이 이에 달려있나요?

이 문맥이 문서를 매우 유용하게 만듭니다."

**사용자가 최소 문서만 원함:**
"이해합니다. 가벼운 버전을 만들어봅시다:
- 1페이지 요약
- 주요 발견사항 (3-5개 항목)
- 1-2개 주요 시각화
- 권장사항

나중에 필요하면 확장할 수 있습니다."

**사용자가 대상 사용자를 모름:**
"계층화된 문서를 만들어봅시다:
- 요약 (경영진용)
- 분석 개요 (이해관계자용)
- 기술 부록 (데이터팀용)

각 수준에 적절한 세부사항이 있습니다."

**분석이 완전히 검증되지 않음:**
"'초안' 상태를 추가하고 문서화합시다:
- 무엇이 검증되었는가
- 무엇이 검토 필요인가
- 열린 질문
- 다음 단계

이는 성급한 의사결정을 방지합니다."

## 고급 옵션

기본 문서화 후 제공:

**대화형 문서**:
"인라인 문서와 함께 Jupyter 노트북을 만들어서 실행 가능한 문서를 만들 수 있습니다."

**자동 문서화**:
"반복 분석을 위해 각 실행으로 자동 업데이트되는 문서를 설정할 수 있습니다."

**문서 표준**:
"팀이 일관성을 보장하도록 문서화 템플릿 및 스타일 가이드를 만들 수 있습니다."

**버전 관리**:
"문서를 Git에 설정하여 적절한 버전 관리, 변경 추적, 검토 프로세스를 할 수 있습니다."

**문서 리뷰**:
"기존 문서를 모범 사례에 대해 검토하고 개선사항을 제안할 수 있습니다."

**지식 기반 통합**:
"문서를 wiki/Confluence/Notion에 연결하여 검색 가능성과 발견성을 높입니다."
