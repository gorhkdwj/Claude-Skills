---
name: executive-summary-generator
description: 상세 분석에서 간결한 임원진 요약을 만드세요. Create concise executive summaries from detailed analysis. Use when preparing board decks, executive briefings, or condensing complex analysis into decision-ready formats.
---

# 임원진 요약 생성기(Executive Summary Generator)

## 단계(Phase)
Phase 6 — 시각화 및 전달

## 입력(Input)
- 이전 스킬: insight-synthesis + impact-quantification
- 받는 파일: `insight-synthesis_report.md` + `impact-quantification_report.md`

## 출력(Output)
- `executive-summary-generator_report.md`

## 빠른 시작(Quick Start)

상세한 분석을 간결하고 의사 결정에 초점을 맞춘 임원진 요약으로 변환하여 몇 시간이 아닌 분 안에 핵심 인사이트와 권장사항을 전달하세요.

## 컨텍스트 요구사항(Context Requirements)

1. **전체 분석(Full Analysis)**: 요약할 완전한 분석
2. **대상(Audience)**: 특정 임원진 및 그들의 우선사항
3. **의사 결정(Decision)**: 이것이 어떤 의사 결정을 알려줄 것인가
4. **제약(Constraints)**: 페이지 제한, 읽을 시간, 형식
5. **컨텍스트(Context)**: 임원진이 이미 알고 있는 것

## 컨텍스트 수집(Context Gathering)

"상세한 분석을 공유하면 다음에 초점을 맞춘 임원진 요약을 만들겠습니다:
- 상위 3-5개 인사이트만
- 명확한 비즈니스 영향
- 구체적인 권장사항
- 임원진이 결정/승인해야 할 사항
보통 최대 1-2페이지."

## 워크플로우(Workflow)

### 단계 1: 핵심 메시지 추출(Extract Core Message)

```python
class ExecutiveSummaryBuilder:
    def __init__(self, analysis_title, exec_audience):
        self.title = analysis_title
        self.audience = exec_audience
        self.situation = ""
        self.insights = []
        self.recommendations = []
        self.decision_needed = ""
        
    def set_situation(self, context):
        """One paragraph: Why this analysis, why now"""
        self.situation = context
    
    def add_insight(self, insight, impact, evidence):
        """Add key finding with business impact"""
        self.insights.append({
            'insight': insight,
            'impact': impact,
            'evidence': evidence
        })
    
    def add_recommendation(self, action, rationale, expected_outcome):
        """Add prioritized recommendation"""
        self.recommendations.append({
            'action': action,
            'rationale': rationale,
            'outcome': expected_outcome
        })
    
    def set_decision(self, decision):
        """What exec needs to decide"""
        self.decision_needed = decision
    
    def generate(self):
        """Create formatted executive summary"""
        
        summary = f"# Executive Summary: {self.title}\n\n"
        summary += f"**For:** {self.audience}\n"
        summary += f"**Date:** {datetime.now().strftime('%B %d, %Y')}\n\n"
        summary += "---\n\n"
        
        # Situation
        summary += "## Situation\n\n"
        summary += f"{self.situation}\n\n"
        
        # Key Insights
        summary += "## Key Insights\n\n"
        for i, insight in enumerate(self.insights, 1):
            summary += f"**{i}. {insight['insight']}**\n"
            summary += f"- Impact: {insight['impact']}\n"
            summary += f"- Evidence: {insight['evidence']}\n\n"
        
        # Recommendations
        summary += "## Recommendations\n\n"
        for i, rec in enumerate(self.recommendations, 1):
            summary += f"**{i}. {rec['action']}**\n"
            summary += f"- Why: {rec['rationale']}\n"
            summary += f"- Expected Outcome: {rec['outcome']}\n\n"
        
        # Decision
        summary += "## Decision Needed\n\n"
        summary += f"{self.decision_needed}\n\n"
        
        return summary

# Example usage
builder = ExecutiveSummaryBuilder(
    "Q4 Customer Churn Analysis",
    "VP Product, CFO"
)

builder.set_situation(
    "Customer churn increased 15% in Q4, putting $2M ARR at risk. Analysis identifies mobile app issues as primary driver. Immediate action required to prevent further losses."
)

builder.add_insight(
    "Mobile users churning at 2x rate of desktop users",
    "$800K ARR at risk from mobile-specific issues",
    "35% mobile churn vs 17% desktop churn. Spike correlates with app update v3.2.0"
)

builder.add_recommendation(
    "Rollback mobile app to previous stable version",
    "Update v3.2.0 introduced performance issues affecting 40% of mobile users",
    "Reduce mobile churn to <20% within 30 days, save $400K ARR"
)

builder.set_decision(
    "Approve immediate app rollback and $150K budget for mobile UX improvements"
)

summary = builder.generate()
print(summary)
```

### 단계 2: 피라미드 원칙 적용(Apply Pyramid Principle)

```python
def apply_pyramid_structure(main_message, supporting_points):
    """Structure: Lead with conclusion, support with evidence"""
    
    structure = {
        'headline': main_message,  # Answer first
        'supporting': supporting_points,  # Then why
        'details': []  # Finally how (optional for execs)
    }
    
    # Format
    output = f"## {structure['headline']}\n\n"
    output += "**Why this matters:**\n"
    for point in structure['supporting']:
        output += f"- {point}\n"
    
    return output

headline = "Immediate mobile app rollback required to stop churn crisis"
support = [
    "$800K ARR at risk from mobile churn spike",
    "Issue traced to recent app update",
    "Rollback can recover 50% of at-risk revenue within 30 days"
]

pyramid = apply_pyramid_structure(headline, support)
print(pyramid)
```

### 단계 3: 모든 것을 정량화(Quantify Everything)

```python
def add_business_metrics(summary_dict):
    """Ensure all insights have numbers"""
    
    enhanced = summary_dict.copy()
    
    # Add financial impact
    enhanced['financial_impact'] = {
        'revenue_at_risk': '$2M ARR',
        'recovery_potential': '$400K in 30 days',
        'investment_needed': '$150K'
    }
    
    # Add metrics
    enhanced['key_metrics'] = {
        'current_churn': '23%',
        'target_churn': '<10%',
        'timeline': '60 days'
    }
    
    # ROI calculation
    enhanced['roi'] = {
        'investment': 150_000,
        'return': 400_000,
        'ratio': '2.7x'
    }
    
    print("💰 Business Metrics:")
    print(f"  Revenue at Risk: {enhanced['financial_impact']['revenue_at_risk']}")
    print(f"  Investment: {enhanced['financial_impact']['investment_needed']}")
    print(f"  ROI: {enhanced['roi']['ratio']}")
    
    return enhanced

metrics = add_business_metrics({})
```

## 컨텍스트 검증(Context Validation)

- [ ] 의사 결정이 명확하게 명시됨
- [ ] 인사이트가 사실 기반임
- [ ] 영향이 정량화됨
- [ ] 권장사항이 구체적임
- [ ] 1-2페이지에 적합함
- [ ] 전문 용어 또는 기술 세부사항 없음

## 출력 템플릿(Output Template)

```
# 임원진 요약(Executive Summary): 4분기 고객 이탈 분석

**대상(For):** 제품 담당 부사장, CFO
**날짜(Date):** 2025년 1월 11일

---

## 상황(Situation)

고객 이탈이 4분기에 15% 증가(8% → 23%)하여 연 200만 달러 수익이 위험에 처했습니다.
분석에서는 모바일 앱 성능 문제가 주요 원인으로 파악되었습니다.
추가 손실을 방지하기 위해 즉시 조치가 필요합니다.

## 핵심 인사이트(Key Insights)

**1. 모바일 사용자가 데스크톱의 2배 이탈**
- 영향: 모바일 관련 문제로 인한 연 80만 달러 수익 위험
- 근거: 모바일 35% vs 데스크톱 17% 이탈. 앱 업데이트 v3.2.0과 일치

**2. 이탈이 안정화되지 않고 가속화됨**
- 영향: 추세가 계속되면 2025년 연 300만 달러 이상 수익 위험
- 근거: 4분기 월간 이탈이 매월 증가(5% → 8% → 12% → 23%)

**3. 복구 캠페인이 이탈한 사용자의 15%만 복구**
- 영향: 복구보다 예방이 더 효과적
- 근거: 과거 복구율은 30%였으나 4분기에 15%로 하락

## 권장사항(Recommendations)

**1. 즉시: 모바일 앱을 v3.1.9로 롤백(우선순위: 중대)**
- 이유: 업데이트 v3.2.0으로 40%의 사용자가 영향을 받는 성능 문제 발생
- 예상 결과: 30일 내 모바일 이탈을 20% 미만으로 감소, 연 40만 달러 절약

**2. 1주: 모바일 사용자 복구 캠페인 시작(우선순위: 높음)**
- 이유: 15% 복구는 고가치 고객에게 여전히 의미가 있음
- 예상 결과: 이탈한 모바일 사용자로부터 연 12만 달러 수익 복구

**3. 1개월: 모바일 UX 개선에 투자(우선순위: 높음)**
- 이유: 재발 방지를 위한 장기적 해결책
- 예상 결과: 경쟁력 있는 모바일 경험, 지속적으로 10% 미만 이탈

## 필요한 의사 결정(Decision Needed)

**승인 필요:**
1. 즉시 모바일 앱 롤백(엔지니어링: 1일)
2. 모바일 UX 개선을 위한 15만 달러 예산
3. 다음 분기를 위한 전담 모바일 팀

**타임라인:** 2월 1일 영향을 위해 1월 15일까지 결정

---

**결론(Bottom Line):** 15만 달러 투자로 연 200만 달러 수익을 절약할 수 있습니다. ROI: 13배. 매주 지연될 때마다 손실 수익이 10만 달러씩 증가합니다.
```

## 일반적인 시나리오(Common Scenarios)

### 시나리오 1: "이사회 자료용 30페이지 분석 축약"
→ 상위 3개 인사이트만 추출
→ 비즈니스 영향으로 주도
→ 인사이트당 한 슬라이드
→ 명확한 요청/의사 결정
→ 세부사항은 부록에

### 시나리오 2: "주간 임원진 브리핑"
→ 표준 템플릿
→ 상황, 인사이트, 조치
→ 메트릭 대시보드
→ 이전 주와 비교
→ 에스컬레이션 강조

### 시나리오 3: "임시 임원진 질문"
→ 먼저 답변(한 문장)
→ 3개 항목으로 지원
→ 전체 분석으로 링크
→ 더 깊이 파고들 제안
→ 1시간 이내에 응답

### 시나리오 4: "월간 비즈니스 검토"
→ 목표 대비 성과
→ 성공과 우려사항 강조
→ 미래 지향적 인사이트
→ 리소스 요청
→ 다음 달 우선사항

## 누락된 컨텍스트 처리(Handling Missing Context)

**길고 산만한 분석:**
"초점을 맞추도록 도와드리겠습니다:
- #1 인사이트가 무엇인가요?
- 이것이 어떤 의사 결정을 알려줄까요?
- 요청사항이 무엇인가요?
그런 다음 임원진 요약으로 구조화하겠습니다."

**너무 많은 기술 세부사항:**
"비즈니스 언어로 번역하겠습니다:
- 기술 용어 교체
- '그래서 어떻게'에 초점
- 영향 정량화
- 권장사항을 구체적으로"

**임원진이 신경 써야 할 것이 불명확함:**
"그들의 우선사항에 맞춰봅시다:
- 수익/성장?
- 비용/효율?
- 위험/규정 준수?
- 고객 만족도?
그에 따라 인사이트를 프레임하세요."

## 고급 옵션(Advanced Options)

**템플릿 라이브러리**: 다양한 임원진 대상을 위한 미리 빌드된 형식

**자동 요약**: 긴 문서에서 핵심 포인트 추출하는 AI

**점진적 공개(Progressive Disclosure)**: 요약 → 필요에 따라 세부사항

**임원진 대시보드**: 항상 업데이트된 주요 메트릭 요약

**의사 결정 로그**: 임원진 의사 결정 및 결과 추적
