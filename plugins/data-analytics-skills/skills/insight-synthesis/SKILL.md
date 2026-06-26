---
name: insight-synthesis
description: 데이터 발견사항을 설득력 있는 인사이트로 변환하세요. Transform data findings into compelling insights. Use when converting analysis results into actionable insights, connecting findings to business impact, or preparing insights for stakeholder communication.
---

# 인사이트 종합(Insight Synthesis)

## 단계(Phase)
Phase 5 — 인사이트 도출

## 입력(Input)
- 이전 스킬: Phase 4 분석 스킬들 (조합에 따라 다름)
- 받는 파일: Phase 4에서 수행한 분석의 `*_result.csv` + `*_report.md`

## 출력(Output)
- `insight-synthesis_report.md`

## 빠른 시작(Quick Start)

데이터 패턴을 비즈니스 영향과 연결함으로써 비즈니스 의사 결정을 주도하는 명확하고 실행 가능한 인사이트로 원본 분석 발견사항을 변환하세요.

## 컨텍스트 요구사항(Context Requirements)

1. **분석 발견사항(Analysis Findings)**: 원본 결과, 통계, 발견된 패턴
2. **비즈니스 컨텍스트(Business Context)**: 비즈니스가 중시하는 것, 현재 우선사항
3. **대상(Audience)**: 누가 이 인사이트가 필요하고 어떻게 사용할 것인가
4. **의사 결정 프레임워크(Decision Framework)**: 이 인사이트가 알려야 할 의사 결정
5. **제약(Constraints)**: 제한사항, 주의사항, 신뢰도 수준

## 컨텍스트 수집(Context Gathering)

### 발견사항(For Findings)을 위해:
"분석 결과를 공유하세요:
- 주요 통계 및 메트릭
- 발견된 패턴 또는 추세
- 발견된 상관관계
- 식별된 이상값
- 가설 검정 결과

예시: '4분기에 이탈율이 15% 증가했습니다. 모바일 사용자가 데스크톱보다 2배 더 이탈하고 있습니다. 최근 앱 업데이트와의 상관관계.'"

### 비즈니스 컨텍스트(For Business Context)를 위해:
"비즈니스 우선사항을 이해하도록 도와주세요:
- 현재 목표/OKR
- 다루고 있는 통증 포인트
- 전략적 이니셔티브
- 이용 가능한 예산/리소스
- 조치 타임라인

이는 인사이트를 흥미로운 것뿐만 아니라 실행 가능한 것으로 프레임하는 데 도움이 됩니다."

### 대상(For Audience)을 위해:
"누가 이 인사이트에 따라 행동할 것인가?
- **임원진**: 높은 수준의 전략적 함축
- **제품 팀**: 기능/UX 함축
- **마케팅**: 캠페인/타겟팅 함축
- **운영**: 프로세스 개선 함축

다양한 대상은 다양한 프레임이 필요합니다."

## 워크플로우(Workflow)

### 단계 1: 발견사항 구조화(Structure Findings)

```python
import pandas as pd
import numpy as np

class InsightSynthesizer:
    def __init__(self, analysis_name):
        self.analysis_name = analysis_name
        self.findings = []
        self.insights = []
    
    def add_finding(self, finding_type, metric, value, context):
        """Log an analysis finding"""
        self.findings.append({
            'type': finding_type,  # trend, comparison, correlation, anomaly
            'metric': metric,
            'value': value,
            'context': context,
            'business_impact': None,
            'recommendation': None
        })
    
    def convert_to_insight(self, finding_idx, impact, recommendation, confidence):
        """Convert finding to actionable insight"""
        finding = self.findings[finding_idx]
        
        insight = {
            'finding': finding,
            'impact': impact,
            'recommendation': recommendation,
            'confidence': confidence,
            'priority': self._assess_priority(impact, confidence)
        }
        
        self.insights.append(insight)
        return insight
    
    def _assess_priority(self, impact, confidence):
        """Determine insight priority"""
        if 'high' in impact.lower() and confidence == 'high':
            return 'critical'
        elif 'high' in impact.lower() or confidence == 'high':
            return 'high'
        elif 'medium' in impact.lower():
            return 'medium'
        else:
            return 'low'

# Initialize
synthesizer = InsightSynthesizer("Q4 Churn Analysis")

# Add findings
synthesizer.add_finding(
    finding_type='trend',
    metric='Churn Rate',
    value='15% increase in Q4',
    context='Previous quarter was 8%, now 23%'
)

synthesizer.add_finding(
    finding_type='comparison',
    metric='Mobile vs Desktop Churn',
    value='2x higher on mobile',
    context='Mobile: 35% churn, Desktop: 17% churn'
)

print("✅ Findings structured")
```

### 단계 2: 비즈니스 영향과 연결(Connect to Business Impact)

```python
# Convert finding to insight with business context

insight_1 = synthesizer.convert_to_insight(
    finding_idx=0,
    impact="High revenue risk: 15% churn increase = $2M ARR at risk. Accelerating trend suggests worsening if unaddressed.",
    recommendation="Immediate win-back campaign for at-risk customers. Investigate root cause (recent product changes, competitor moves).",
    confidence='high'
)

insight_2 = synthesizer.convert_to_insight(
    finding_idx=1,
    impact="Mobile represents 40% of user base. 2x churn rate means disproportionate loss of mobile users. Mobile-first strategy at risk.",
    recommendation="Audit mobile app experience. Recent app update (v3.2.0) correlated with spike - consider rollback or hotfix.",
    confidence='high'
)

print(f"✅ Created {len(synthesizer.insights)} actionable insights")
```

### 단계 3: 인사이트 프레임워크 적용(Apply Insight Framework)

```python
def apply_insight_framework(finding, business_context):
    """
    Use So What? - Why? - Now What? framework
    """
    
    insight = {}
    
    # SO WHAT? (Why it matters)
    insight['so_what'] = f"This means {finding['value']} which affects {business_context['impact_area']}"
    
    # WHY? (Root cause hypothesis)
    insight['why'] = f"Likely driven by {business_context['hypothesis']}"
    
    # NOW WHAT? (Action)
    insight['now_what'] = f"We should {business_context['action']}"
    
    # Expected outcome
    insight['expected_outcome'] = business_context.get('expected_outcome')
    
    return insight

# Example
finding = synthesizer.findings[0]
context = {
    'impact_area': 'monthly recurring revenue and growth targets',
    'hypothesis': 'recent app update degrading mobile UX, competitor launched similar product',
    'action': 'immediately investigate app update, run win-back campaign, monitor competitor',
    'expected_outcome': 'Reduce churn to <10% within 60 days, recover $500K ARR'
}

structured_insight = apply_insight_framework(finding, context)

print("\n📊 Structured Insight:")
print(f"  SO WHAT: {structured_insight['so_what']}")
print(f"  WHY: {structured_insight['why']}")
print(f"  NOW WHAT: {structured_insight['now_what']}")
```

### 단계 4: 인사이트 우선순위 지정(Prioritize Insights)

```python
def prioritize_insights(insights):
    """Rank insights by impact and urgency"""
    
    priority_map = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1}
    
    # Sort by priority
    sorted_insights = sorted(
        insights,
        key=lambda x: priority_map[x['priority']],
        reverse=True
    )
    
    print("\n🎯 Prioritized Insights:\n")
    for i, insight in enumerate(sorted_insights, 1):
        print(f"{i}. [{insight['priority'].upper()}] {insight['finding']['metric']}")
        print(f"   Impact: {insight['impact'][:80]}...")
        print(f"   Action: {insight['recommendation'][:80]}...")
        print()
    
    return sorted_insights

prioritized = prioritize_insights(synthesizer.insights)
```

### 단계 5: 임원진 요약 생성(Generate Executive Summary)

```python
def generate_executive_summary(insights, analysis_name):
    """Create concise executive summary"""
    
    summary = f"# Executive Summary: {analysis_name}\n\n"
    
    # Top 3 insights
    summary += "## Key Insights\n\n"
    for i, insight in enumerate(insights[:3], 1):
        summary += f"**{i}. {insight['finding']['metric']}**\n"
        summary += f"- Finding: {insight['finding']['value']}\n"
        summary += f"- Impact: {insight['impact']}\n"
        summary += f"- Action: {insight['recommendation']}\n\n"
    
    # Bottom line
    summary += "## Bottom Line\n\n"
    summary += f"Immediate action required on {len([i for i in insights if i['priority'] in ['critical', 'high']])} high-priority issues. "
    summary += f"Estimated business impact: $2M+ ARR at risk if unaddressed.\n"
    
    return summary

exec_summary = generate_executive_summary(prioritized, "Q4 Churn Analysis")
print(exec_summary)
```

## 컨텍스트 검증(Context Validation)

- [ ] 발견사항이 사실상 정확함
- [ ] 비즈니스 영향이 현실적임
- [ ] 권장사항이 실행 가능함
- [ ] 신뢰도 수준이 정직함
- [ ] 대상 요구사항을 고려함

## 출력 템플릿(Output Template)

```
# 핵심 인사이트(Key Insights): 4분기 이탈 분석

## 중대 인사이트 #1: 모바일 이탈 위기(Mobile Churn Crisis)

**발견사항(Finding):** 모바일 사용자가 데스크톱의 2배 이탈(35% vs 17%)

**그래서 어떻게(So What):**
- 모바일 = 사용자 기반의 40%, 불균형 손실
- 모바일 우선 전략 위협
- 최근 코호트에 집중(앱 업데이트 이후)

**왜(Why):**
- 앱 업데이트 v3.2.0으로 성능 문제 발생
- 경쟁사가 개선된 모바일 앱 출시
- 모바일 온보딩이 덜 효과적

**이제 어떻게(Now What):**
1. 즉시: 앱을 v3.1.9(안정적 버전)로 롤백
2. 1주: 모바일 경험에 대한 긴급 UX 감사
3. 2주: 모바일 복구 캠페인 시작
4. 1개월: 모바일 온보딩 재설계

**예상 결과(Expected Outcome):**
60일 내에 모바일 이탈을 20% 미만으로 감소, 연 50만 달러 절약

**신뢰도(Confidence):** 높음(사용자 피드백으로 검증됨, 앱 출시와 상관관계)

---

## 높은 우선순위 인사이트 #2: 이탈 가속화(Churn Accelerating)

**발견사항(Finding):** 이탈 15% 증가(8% → 23% 한 분기 내)

**영향(Impact):** 연 200만 달러 수익이 위험에 처함, 성장 목표 훼손

**조치(Action):** 근본 원인 조사 + 보유 프로그램

**신뢰도(Confidence):** 높음
```

## 일반적인 시나리오(Common Scenarios)

### 시나리오 1: "분석을 임원진 프레젠테이션으로 변환"
→ 상위 3-5개 인사이트 추출
→ 비즈니스 영향으로 프레임
→ 권장사항으로 주도
→ 데이터로 지원
→ 다음 단계 포함

### 시나리오 2: "이해관계자가 왜 신경 써야 할까?"
→ OKR/목표와 연결
→ 비즈니스 영향 정량화($, 고객, 시간)
→ 긴급성 표시(조치하지 않으면 어떻게 되는가)
→ 권장사항을 구체적으로
→ 신뢰도 수준 제공

### 시나리오 3: "제시할 발견사항이 너무 많음"
→ 영향으로 우선순위 지정
→ 관련 발견사항 그룹화
→ 실행 가능한 인사이트에 초점
→ 나머지는 부록에 저장
→ 대상에 맞춤

### 시나리오 4: "발견사항이 충돌하거나 불명확함"
→ 불확실성 인정
→ 대안 해석 제시
→ 검증 접근법 권장
→ 임시 인사이트 제공
→ 다음 분석 설정

### 시나리오 5: "인사이트 라이브러리 만들기"
→ 인사이트 패턴 문서화
→ 일반적인 인사이트 유형 템플릿
→ 메트릭 → 인사이트 매핑 구축
→ 셀프 서비스 인사이트 활성화
→ 인사이트 결과 추적

## 누락된 컨텍스트 처리(Handling Missing Context)

**컨텍스트 없이 원본 숫자만:**
"데이터가 변했다는 것은 알 수 있지만 비즈니스 컨텍스트가 필요합니다:
- 이 메트릭을 왜 신경 써야 할까요?
- 허용 범위는 무엇인가요?
- 실제로 무엇을 할 수 있나요?
발견사항을 비즈니스 영향과 연결해봅시다."

**조치해야 할 것이 불명확함:**
"역순으로 생각해봅시다:
- 누가 조치를 취할 권한이 있나요?
- 어떤 레버를 당길 수 있나요?
- 현실적인 타임라인은 무엇인가요?
그런 다음 인사이트를 실행 가능한 권장사항으로 프레임하세요."

**발견사항에 대한 신뢰도가 낮음:**
"불확실성에 대해 투명하세요:
- 무엇을 알고 있는지 vs 의심하는지 명시
- 신뢰도 수준 제공
- 검증 권장
- 과도한 자신감 있는 주장 피하기"

## 고급 옵션(Advanced Options)

**인사이트 채점 모델**: 영향 × 신뢰도 × 실행 가능성으로 인사이트 가중치 부여

**인사이트 템플릿**: 일반적인 분석 유형에 대한 미리 빌드된 프레임워크

**자동화된 인사이트**: 통계적 유의성, 이상값, 패턴 스캔

**인사이트 추적**: 어떤 인사이트가 행동과 결과로 이어졌는지 모니터링

**경쟁 인사이트**: 업계 벤치마크, 경쟁사와 비교
