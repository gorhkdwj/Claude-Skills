---
name: data-narrative-builder
description: 설득력 있는 데이터 중심의 내러티브와 스토리를 구축하세요. Build compelling data-driven narratives and stories. Use when presenting analysis results, creating reports, or communicating data insights through storytelling frameworks.
---

# 데이터 내러티브 빌더(Data Narrative Builder)

## 단계(Phase)
Phase 6 — 시각화 및 전달

## 입력(Input)
- 이전 스킬: visualization-builder
- 받는 파일: `visualization-builder_report.md`

## 출력(Output)
- `data-narrative-builder_report.md`

## 빠른 시작(Quick Start)

검증된 스토리텔링 프레임워크를 사용하여 데이터 분석을 청중을 매료시키고 이해를 구축하고 행동을 주도하는 설득력 있는 내러티브로 변환하세요.

## 컨텍스트 요구사항(Context Requirements)

1. **데이터/분석(Data/Analysis)**: 전달할 핵심 발견사항
2. **대상(Audience)**: 누가 말을 듣고 있고 그들의 배경
3. **목표(Goal)**: 어떤 행동 또는 이해를 원하는가
4. **형식(Format)**: 프레젠테이션, 리포트, 이메일, 대시보드
5. **제약(Constraints)**: 시간, 길이, 형식성 수준

## 컨텍스트 수집(Context Gathering)

"데이터 내러티브를 구축하려면:
- 중심 인사이트/메시지가 무엇인가요?
- 대상이 누구이고 무엇을 중요하게 생각하나요?
- 그들이 무엇을 하거나 이해하기를 원하나요?
- 어떻게 전달할 건가요?
- 처리해야 할 민감한 주제가 있나요?"

## 워크플로우(Workflow)

### 단계 1: 내러티브 구조 선택(Choose Narrative Structure)

```python
class DataNarrative:
    """Build data-driven stories using proven frameworks"""
    
    FRAMEWORKS = {
        'situation_complication_resolution': {
            'structure': ['Situation', 'Complication', 'Resolution'],
            'use_when': 'Presenting problem and solution'
        },
        'hero_journey': {
            'structure': ['Status Quo', 'Incident', 'Quest', 'Discovery', 'Transformation'],
            'use_when': 'Change management, transformation stories'
        },
        'before_after_bridge': {
            'structure': ['Before', 'After', 'Bridge'],
            'use_when': 'Demonstrating impact of change'
        },
        'sparklines': {
            'structure': ['What Is', 'What Could Be', 'Contrast', 'Call to Action'],
            'use_when': 'Inspiring vision, motivating action'
        }
    }
    
    def __init__(self, framework='situation_complication_resolution'):
        self.framework = framework
        self.structure = self.FRAMEWORKS[framework]['structure']
        self.sections = {section: '' for section in self.structure}
        self.data_points = []
    
    def add_section(self, section_name, content):
        if section_name in self.sections:
            self.sections[section_name] = content
    
    def add_data_point(self, value, context, emotional_hook=None):
        self.data_points.append({
            'value': value,
            'context': context,
            'hook': emotional_hook
        })
    
    def build(self):
        narrative = f"# Data Narrative\n\n"
        narrative += f"**Framework:** {self.framework.replace('_', ' ').title()}\n\n"
        narrative += "---\n\n"
        
        for section in self.structure:
            if self.sections[section]:
                narrative += f"## {section}\n\n"
                narrative += f"{self.sections[section]}\n\n"
        
        return narrative

# Example: Situation-Complication-Resolution
narrative = DataNarrative('situation_complication_resolution')

narrative.add_section('Situation', 
    "For the past 3 years, our customer retention has been steady at 85%, meeting industry benchmarks and supporting predictable revenue growth."
)

narrative.add_section('Complication',
    "In Q4, retention dropped to 70% - a 15 percentage point decline. This puts $2M ARR at risk and threatens our growth trajectory. Analysis shows mobile users are churning at twice the rate of desktop users, correlating with our recent app update."
)

narrative.add_section('Resolution',
    "We can recover by rolling back the problematic app update (immediate), launching targeted win-back campaigns (week 1), and investing in mobile UX improvements (month 1). This three-phase approach can restore retention to 82% and save $1.6M ARR within 90 days."
)

story = narrative.build()
print(story)
```

### 단계 2: 감정적 호(Emotional Arc) 적용(Apply Emotional Arc)

```python
def add_emotional_journey(narrative_sections):
    """Layer emotional progression onto data narrative"""
    
    emotional_arc = {
        'Situation': {
            'emotion': 'Stability/Comfort',
            'tone': 'Neutral, establishing context',
            'data_role': 'Baseline, historical performance'
        },
        'Complication': {
            'emotion': 'Tension/Concern',
            'tone': 'Urgent, problem-focused',
            'data_role': 'The surprise, the deviation, the gap'
        },
        'Resolution': {
            'emotion': 'Hope/Confidence',
            'tone': 'Solution-oriented, forward-looking',
            'data_role': 'Projected outcomes, success metrics'
        }
    }
    
    enhanced = {}
    for section, content in narrative_sections.items():
        arc = emotional_arc.get(section, {})
        enhanced[section] = {
            'content': content,
            'emotion': arc.get('emotion'),
            'delivery_notes': arc.get('tone')
        }
    
    return enhanced

enhanced_story = add_emotional_journey(narrative.sections)
print("\n✅ Emotional arc applied")
```

### 단계 3: 데이터 포인트 짜여 넣기(Weave in Data Points)

```python
def integrate_data_strategically(narrative, data_points):
    """Place data where it maximizes impact"""
    
    # Principles:
    # 1. Lead with most compelling stat
    # 2. Use round numbers for easy recall
    # 3. Compare to familiar benchmarks
    # 4. Show trend, not just point-in-time
    # 5. Humanize big numbers
    
    enhanced = narrative
    
    # Example transformations
    transformations = {
        'raw': '$2,000,000',
        'rounded': '$2M',
        'contextualized': '$2M (20% of annual revenue)',
        'humanized': '$2M affecting 500 customer relationships',
        'visualized': '⬇️ 15% decline = $2M at risk'
    }
    
    print("\n📊 Data Integration Techniques:")
    for style, example in transformations.items():
        print(f"  {style.title()}: {example}")
    
    return enhanced

enhanced_narrative = integrate_data_strategically(story, narrative.data_points)
```

### 단계 4: 모멘텀 및 속도 구축(Build Momentum and Pacing)

```python
def structure_pacing(sections):
    """Control information flow and build momentum"""
    
    pacing_guide = {
        'opening': {
            'length': 'short',
            'content': 'hook + context',
            'purpose': 'grab attention, set stage'
        },
        'development': {
            'length': 'medium',
            'content': 'build tension, explore problem',
            'purpose': 'create urgency, show impact'
        },
        'climax': {
            'length': 'short',
            'content': 'key insight or turning point',
            'purpose': 'aha moment'
        },
        'resolution': {
            'length': 'medium',
            'content': 'solution and path forward',
            'purpose': 'inspire confidence, enable action'
        },
        'closing': {
            'length': 'short',
            'content': 'call to action',
            'purpose': 'clear next steps'
        }
    }
    
    print("\n⚡ Pacing Structure:")
    for phase, guide in pacing_guide.items():
        print(f"  {phase.title()}: {guide['length']} - {guide['purpose']}")
    
    return pacing_guide

pacing = structure_pacing(narrative.sections)
```

### 단계 5: 시각적 스토리텔링 추가(Add Visual Storytelling)

```python
def plan_visual_narrative(narrative_structure):
    """Map visualizations to narrative flow"""
    
    visual_plan = {
        'Situation': [
            {'type': 'line_chart', 'data': '3-year retention trend', 'message': 'Historical stability'},
            {'type': 'benchmark', 'data': 'vs industry average', 'message': 'Meeting standards'}
        ],
        'Complication': [
            {'type': 'before_after', 'data': 'Q3 vs Q4 retention', 'message': 'Dramatic drop'},
            {'type': 'comparison', 'data': 'mobile vs desktop churn', 'message': 'Mobile crisis'},
            {'type': 'timeline', 'data': 'app update correlation', 'message': 'Root cause'}
        ],
        'Resolution': [
            {'type': 'roadmap', 'data': 'three-phase plan', 'message': 'Clear path forward'},
            {'type': 'projection', 'data': 'recovery trajectory', 'message': 'Expected outcomes'}
        ]
    }
    
    print("\n🎨 Visual Narrative Plan:")
    for section, visuals in visual_plan.items():
        print(f"\n  {section}:")
        for v in visuals:
            print(f"    • {v['type']}: {v['message']}")
    
    return visual_plan

visual_plan = plan_visual_narrative(narrative.sections)
```

### 단계 6: 오프닝 훅 제작(Craft Opening Hook)

```python
def create_compelling_hook(main_insight, audience):
    """Start with attention-grabbing opening"""
    
    hook_techniques = {
        'surprising_stat': "85% retention for 3 years. Then suddenly: 70%. What happened?",
        'question': "What if I told you we lost $2M in 90 days - and almost no one noticed?",
        'bold_claim': "Our mobile app update just cost us $2 million.",
        'story': "Three months ago, Sarah in finance asked a routine question: 'Why are refunds up?' That question led us to discover...",
        'contrast': "While desktop users stayed loyal, mobile users were quietly walking away."
    }
    
    print("\n🎣 Hook Options:")
    for technique, example in hook_techniques.items():
        print(f"  {technique.replace('_', ' ').title()}:")
        print(f"    '{example}'")
    
    # For executives: surprising_stat or bold_claim
    # For technical: question or contrast
    # For general: story
    
    return hook_techniques

hooks = create_compelling_hook("Mobile churn crisis", "executives")
```

### 단계 7: 명확한 행동 촉구(CTA)로 종료(End with Clear Call to Action)

```python
def craft_call_to_action(recommendations, urgency):
    """Create specific, actionable closing"""
    
    cta = {
        'decision_needed': "Approve immediate app rollback and $150K mobile UX investment",
        'timeline': "Decision needed by Friday (Jan 15) for Feb 1 implementation",
        'accountability': "Engineering: Rollback | Product: UX fixes | Sales: Win-back campaign",
        'follow_up': "Weekly check-ins on recovery metrics starting Jan 22",
        'success_criteria': "Return to >80% retention by March 31"
    }
    
    # Format CTA
    cta_text = f"""
## What We Need From You

**Decision:** {cta['decision_needed']}

**Timeline:** {cta['timeline']}

**Who Does What:**
- Engineering: App rollback (immediate)
- Product: UX improvements (30 days)
- Sales: Win-back campaign (ongoing)

**Success Metrics:** {cta['success_criteria']}

**Next Steps:** {cta['follow_up']}
    """
    
    print(cta_text)
    return cta

cta = craft_call_to_action([], 'high')
```

## 컨텍스트 검증(Context Validation)

- [ ] 내러티브가 명확한 시작, 중간, 끝을 가짐
- [ ] 데이터가 이야기를 뒷받침함(압도하지 않음)
- [ ] 대상 관점을 고려함
- [ ] 감정적 여정이 의도적임
- [ ] 행동 촉구가 구체적임
- [ ] 시각화가 이해를 향상시킴

## 출력 템플릿(Output Template)

```
# [이야기를 암시하는 설득력 있는 제목]

## 상황 설정(The Setup) (30초)

3년 동안 고객 보유율은 85%로 안정적으로 유지되었으며, 업계 벤치마크를 충족하고 예측 가능한 연 1천만 달러 수익 성장을 지원했습니다.

[시각: 안정성을 보여주는 3년 추세선]

## 반전(The Twist) (60초)

그러다 4분기가 되었습니다. 보유율은 단 90일 만에 70%로 급락했습니다.

연 200만 달러 수익이 위험에 처했습니다. 성장 전망이 위협받고 있습니다.

[시각: 전후 비교]

하지만 우리가 예상하지 못했던 것이 있습니다: 모든 곳에서 발생하지 않았습니다.

데스크톱 사용자? 여전히 85% 충성도.
모바일 사용자? 35% 이탈 - **2배의 비율**.

[시각: 모바일 vs 데스크톱 분할]

## 발견(The Discovery) (45초)

무엇이 변했을까요? 우리의 데이터가 명확한 이야기를 말해줍니다:

• 11월 15일: 모바일 앱 업데이트 v3.2.0 출시
• 11월 20일: 모바일 이탈의 첫 번째 급증
• 12월 31일: 모바일 이탈율 35%에 도달

타이밍은 부인할 수 없습니다. 상관관계는 강합니다.

[시각: 앱 출시 및 이탈 급증이 있는 타임라인]

## 앞으로의 길(The Path Forward) (90초)

우리는 계획이 있습니다. 3단계, 90일, 높은 확신도.

**단계 1(즉시):** 앱을 안정적인 버전으로 롤백
- 예상 영향: 2주 내에 이탈 급증 중지
- 위험: 낮음(검증된 안정적인 코드로 복원)

**단계 2(1주):** 모바일 사용자 복구 캠페인 시작
- 예상 영향: 손실된 사용자의 15% 복구 = 연 30만 달러 수익
- 위험: 중간(제안의 매력에 따라 다름)

**단계 3(1개월):** 모바일 UX 개선에 15만 달러 투자
- 예상 영향: 장기 모바일 보유율 80% 이상
- 위험: 낮음(예산 승인됨, 팀 준비됨)

[시각: 예상 복구 곡선이 있는 90일 로드맵]

## 요청(The Ask) (30초)

**승인이 필요합니다.**

투자: 15만 달러
수익: 위험에 처한 200만 달러 중 160만 달러 절약
타임라인: 월요일 롤백을 위해 금요일까지 결정

매주 기다릴 때마다 손실 수익이 10만 달러씩 증가합니다.

**진행 승인이 나셨나요?**
```

## 일반적인 시나리오(Common Scenarios)

### 시나리오 1: "회의적인 대상에게 분석 제시"
→ 그들의 우려사항으로 시작
→ 반박 의견 인정
→ 데이터로 신용성 구축
→ 관점을 이해함을 보여주기
→ 낮은 위험 다음 단계로 종료

### 시나리오 2: "월간 메트릭을 스토리로 변환"
→ 내러티브 스레드 찾기
→ 무엇이 변했고 왜 중요한지
→ 메트릭을 비즈니스 결과와 연결
→ 성과와 우려사항 강조
→ 미래 지향적 행동 항목

### 시나리오 3: "복잡한 분석을 간단하게 설명"
→ 방법이 아닌 인사이트로 시작
→ 유추 및 은유 사용
→ 점진적 복잡성 공개
→ 시각적 스토리텔링
→ 각 발견사항에 "그래서 어떻게?"

### 시나리오 4: "팀을 데이터 인사이트 중심으로 결집"
→ 영웅의 여정 프레임워크
→ 팀을 주인공으로
→ 데이터를 가이드/멘토로
→ 행동을 추구로
→ 성공을 변화로

## 누락된 컨텍스트 처리(Handling Missing Context)

**데이터만 있고 스토리가 없는 경우:**
"모든 데이터셋에는 스토리가 있습니다:
- 무엇이 변했나요?
- 왜 중요한가요?
- 무엇을 해야 하나요?
내러티브 스레드를 찾아봅시다."

**사실의 지루한 제시:**
"사실만으로는 사람들을 움직이지 못합니다. 다음을 추가하세요:
- 감정적 연결(고객에 미치는 영향)
- 긴장(위험에 처한 것)
- 해결(앞으로의 길)
- 행동 촉구(구체적인 다음 단계)"

**따라가기에 너무 복잡함:**
"스토리를 단순화하세요:
- 하나의 주요 메시지
- 세 가지 지원 포인트
- 다른 모든 것 제거
관심 있는 사람을 위해 부록에 상세사항"

## 고급 옵션(Advanced Options)

**스토리 템플릿**: 일반적인 시나리오를 위한 미리 빌드된 내러티브 구조

**데이터 스토리텔링 워크샵**: 팀에 내러티브 기법 교육

**내러티브 테스트**: 다양한 스토리 구조의 A/B 테스트

**자동화된 인사이트**: AI 생성 내러티브 요약

**인터랙티브 스토리텔링**: 스크롤 스토리텔링, 데이터 중심 경험
