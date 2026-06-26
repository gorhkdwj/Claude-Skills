---
name: analysis-assumptions-log
description: 분석 가정 및 의사결정을 추적하고 문서화합니다. 분석 선택 시, 거래 비용 문서화, 투명성 보장, 분석 작업의 감시 추적 생성 시 사용하세요. | Track and document analytical assumptions and decisions. Use when making analytical choices, documenting trade-offs, ensuring transparency, or creating audit trails for analytical work.
---

# 분석 가정 로그(Analysis Assumptions Log)

## 단계(Phase)
단계 3 — 지식 축적

## 입력(Input)
- 이전 스킬: data-quality-audit + schema-mapper
- 받는 파일: `data-quality-audit_result.csv` + `schema-mapper_report.md`

## 출력(Output)
- `analysis-assumptions-log_report.md`

## 빠른 시작(Quick Start)

분석 중에 수립된 모든 가정, 의사결정, 거래 비용을 체계적으로 문서화하여 투명성, 재현성, 정보 의사결정을 보장하세요.

## 문맥 요구사항(Context Requirements)

가정 로깅 전에 필요한 것:

1. **분석 문맥(Analysis Context)**: 어떤 분석을 수행 중인가
2. **가정(Assumptions Made)**: 명시적 및 암시적 가정
3. **의사결정 지점(Decision Points)**: 선택이 있었던 곳
4. **근거(Rationale)**: 각 가정/의사결정의 이유
5. **영향 평가(Impact Assessment)**: 가정이 잘못될 경우 어떻게 되는가

## 문맥 수집(Context Gathering)

### 분석 문맥을 위해:
"우리가 어떤 분석의 가정을 문서화하고 있나요?

**필요한 문맥:**
- 분석 목표
- 주요 이해관계자
- 정보를 제공하는 의사결정
- 시간 민감성
- 위험 허용도

예: '고객 이탈 예측 모델은 유지팀용. 높은 현황 - $2M 유지 예산을 정보 제공합니다.'"

### 가정을 위해:
"어떤 가정을 하고 있나요? 분류해봅시다:

**데이터 가정:**
- 데이터 품질/완전성
- 샘플 대표성
- 누락 값 처리
- 이상치 처리

**비즈니스 로직 가정:**
- 지표 정의
- 고객 세분화 규칙
- 시간 윈도우
- 인과관계 vs 상관관계

**통계 가정:**
- 분포 가정
- 관찰의 독립성
- 정상성
- 모델 가정

**기술 가정:**
- 시스템 성능
- 데이터 신선도
- 처리 한계"

### 의사결정 지점을 위해:
"결과에 영향을 미치는 선택을 어디서 했나요?

**일반적인 의사결정 지점:**
- 포함/제외할 데이터
- 엣지 케이스 처리 방법
- 선택한 통계 방법
- 설정한 임계값
- 정의된 세그먼트
- 선택한 시간 기간

**선택하지 않은 대안**과 그 이유를 문서화하세요."

### 근거를 위해:
"각 가정/의사결정을 왜 했나요?

**좋은 근거:**
- '업계 표준 접근법'
- '이전 분석에서 검증됨'
- '이해관계자 요구사항'
- '데이터 품질 제약'
- '계산 한계'
- '시간 제약'

**나쁜 근거:**
- '합리적인 것처럼 보임'
- '기본 설정'
- '항상 이렇게 했음'

정직하고 구체적이세요!"

### 영향을 위해:
"가정이 잘못될 경우 어떻게 되나요?

**영향 평가:**
- 잘못될 경우 최선의 시나리오
- 잘못될 경우 가장 가능성 있는 시나리오
- 잘못될 경우 최악의 시나리오
- 잘못될 확률
- 검증 비용
- 잘못될 경우의 비용

이것은 어떤 가정을 검증해야 하는지 우선순위를 정하는 데 도움이 됩니다."

## 워크플로우(Workflow)

### 단계 1: 가정 로그 구조 생성

```python
import pandas as pd
from datetime import datetime
import json

class AssumptionLog:
    """
    분석적 가정 및 의사결정을 구조적으로 로깅
    """

    def __init__(self, analysis_name, analyst):
        self.analysis_name = analysis_name
        self.analyst = analyst
        self.created_date = datetime.now()
        self.assumptions = []
        self.decisions = []
        self.validations = []

    def log_assumption(self,
                      category,
                      assumption,
                      rationale,
                      confidence,
                      impact_if_wrong,
                      validation_plan=None):
        """
        새 가정 로깅
        """

        entry = {
            'id': len(self.assumptions) + 1,
            'timestamp': datetime.now().isoformat(),
            'category': category,
            'assumption': assumption,
            'rationale': rationale,
            'confidence': confidence,  # high, medium, low
            'impact_if_wrong': impact_if_wrong,
            'validation_plan': validation_plan,
            'status': 'active',
            'validated': False
        }

        self.assumptions.append(entry)

        return entry['id']

    def log_decision(self,
                    decision_point,
                    chosen_option,
                    alternatives_considered,
                    rationale,
                    trade_offs):
        """
        분석적 의사결정 로깅
        """

        entry = {
            'id': len(self.decisions) + 1,
            'timestamp': datetime.now().isoformat(),
            'decision_point': decision_point,
            'chosen': chosen_option,
            'alternatives': alternatives_considered,
            'rationale': rationale,
            'trade_offs': trade_offs
        }

        self.decisions.append(entry)

        return entry['id']

    def validate_assumption(self, assumption_id, validation_result, notes):
        """
        가정 검증 기록
        """

        # 가정 찾기
        assumption = next((a for a in self.assumptions if a['id'] == assumption_id), None)

        if assumption:
            assumption['validated'] = True
            assumption['validation_result'] = validation_result
            assumption['validation_notes'] = notes
            assumption['validation_date'] = datetime.now().isoformat()

            self.validations.append({
                'assumption_id': assumption_id,
                'result': validation_result,
                'date': datetime.now().isoformat(),
                'notes': notes
            })

    def get_critical_assumptions(self):
        """
        높은 영향, 낮은 신뢰의 가정 식별
        """

        critical = [
            a for a in self.assumptions
            if a['confidence'] == 'low' and
            a['impact_if_wrong'] in ['high', 'critical']
            and not a['validated']
        ]

        return critical

    def export_to_markdown(self):
        """
        마크다운 문서 생성
        """

        doc = f"# 가정 로그: {self.analysis_name}\n\n"
        doc += f"**분석가:** {self.analyst}\n"
        doc += f"**생성:** {self.created_date.strftime('%Y-%m-%d')}\n"
        doc += f"**마지막 업데이트:** {datetime.now().strftime('%Y-%m-%d')}\n\n"
        doc += "---\n\n"

        # 요약 통계
        doc += "## 요약(Summary)\n\n"
        doc += f"- 총 가정: {len(self.assumptions)}\n"
        doc += f"- 총 의사결정: {len(self.decisions)}\n"

        validated = sum(1 for a in self.assumptions if a['validated'])
        doc += f"- 검증됨: {validated}/{len(self.assumptions)}\n"

        critical = len(self.get_critical_assumptions())
        if critical > 0:
            doc += f"- ⚠️  중요 미검증: {critical}\n"

        doc += "\n---\n\n"

        # 가정
        doc += "## 가정(Assumptions)\n\n"

        for category in ['data', 'business_logic', 'statistical', 'technical']:
            cat_assumptions = [a for a in self.assumptions if a['category'] == category]

            if cat_assumptions:
                doc += f"### {category.replace('_', ' ').title()}\n\n"

                for assum in cat_assumptions:
                    doc += f"**#{assum['id']}: {assum['assumption']}**\n\n"
                    doc += f"- **근거:** {assum['rationale']}\n"
                    doc += f"- **신뢰도:** {assum['confidence'].upper()}\n"
                    doc += f"- **잘못될 경우 영향:** {assum['impact_if_wrong']}\n"

                    if assum['validated']:
                        doc += f"- **검증됨:** ✅ {assum['validation_result']}\n"
                    else:
                        doc += f"- **검증됨:** ❌ 아직 검증 안 됨\n"

                    if assum.get('validation_plan'):
                        doc += f"- **검증 계획:** {assum['validation_plan']}\n"

                    doc += "\n"

        # 의사결정
        doc += "## 주요 의사결정(Key Decisions)\n\n"

        for decision in self.decisions:
            doc += f"**의사결정 #{decision['id']}: {decision['decision_point']}**\n\n"
            doc += f"- **선택:** {decision['chosen']}\n"
            doc += f"- **검토된 대안:**\n"
            for alt in decision['alternatives']:
                doc += f"  - {alt}\n"
            doc += f"- **근거:** {decision['rationale']}\n"
            doc += f"- **거래 비용:** {decision['trade_offs']}\n\n"

        return doc

    def save(self, filepath):
        """
        파일로 로그 저장
        """

        data = {
            'analysis_name': self.analysis_name,
            'analyst': self.analyst,
            'created_date': self.created_date.isoformat(),
            'assumptions': self.assumptions,
            'decisions': self.decisions,
            'validations': self.validations
        }

        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)

# 로그 초기화
log = AssumptionLog(
    analysis_name="고객 이탈 예측 모델",
    analyst="데이터 과학팀"
)

print("✅ 가정 로그 초기화됨")
```

### 단계 2: 데이터 가정 로깅

```python
# 예시: 데이터 관련 가정 로깅

# 가정 1: 샘플 대표성
log.log_assumption(
    category='data',
    assumption='최근 90일 데이터가 향후 행동을 대표함',
    rationale='90일은 최근 제품 변경과 계절 패턴을 포함',
    confidence='medium',
    impact_if_wrong='모델이 향후 기간으로 일반화되지 않을 수 있음. 최근 이상 현상에 오버핏할 수 있음.',
    validation_plan='다른 시간 기간의 홀드아웃 데이터에서 모델 테스트'
)

# 가정 2: 누락 데이터
log.log_assumption(
    category='data',
    assumption='참여 데이터가 누락된 사용자는 비활성 (데이터 품질 문제 아님)',
    rationale='100개 샘플의 수동 검사에서 패턴 확인됨',
    confidence='high',
    impact_if_wrong='활성 사용자를 비활성으로 오분류. 영향을 받는 사용자의 <1%.',
    validation_plan='특정 사용자 ID에 대해 제품팀과 현지 확인'
)

# 가정 3: 이탈 정의
log.log_assumption(
    category='business_logic',
    assumption='30일 활동 없으면 "이탈" 사용자',
    rationale='이해관계자 요구사항. 구독 청구 주기와 일치.',
    confidence='high',
    impact_if_wrong='낮음 - 이것은 우리가 따라야 할 비즈니스 정의',
    validation_plan='해당 안 함 - 이것은 요구사항이지 가정이 아님'
)

print(f"✅ {len(log.assumptions)}개 가정 로깅됨")
```

### 단계 3: 의사결정 지점 로깅

```python
# 예시: 분석 중에 수립된 주요 의사결정 로깅

# 의사결정 1: 기능 선택
log.log_decision(
    decision_point='이탈 모델에 포함할 기능',
    chosen_option='모든 참여 기능 사용 (세션, 이벤트, 기능 사용)',
    alternatives_considered=[
        '핵심 기능만 (세션, 마지막 활동)',
        '인구통계 기능 포함 (나이, 위치)',
        '외부 데이터 추가 (경제 지표)'
    ],
    rationale='EDA에서 참여 기능이 가장 예측력 있음. 인구통계는 개인 정보 우려. 외부 데이터는 바로 사용 불가.',
    trade_offs='더 많은 기능 = 더 많은 복잡성. 오버핏 위험. 하지만 더 나은 예측력.'
)

# 의사결정 2: 모델 선택
log.log_decision(
    decision_point='이탈 모델에 사용할 알고리즘',
    chosen_option='그래디언트 부스팅 (XGBoost)',
    alternatives_considered=[
        '로지스틱 회귀 (해석 가능)',
        '랜덤 포레스트 (견고함)',
        '신경망 (유연함)'
    ],
    rationale='XGBoost는 교차 검증에서 최고 성능 (AUC 0.87 vs 0.82 LR). 이해관계자가 정확도를 해석성보다 우선시.',
    trade_offs='로지스틱 회귀보다 덜 해석 가능. 더 긴 훈련 시간. 하지만 5% 정확도 향상 가치 있음.'
)

# 의사결정 3: 임계값 설정
log.log_decision(
    decision_point='이탈 예측 확률 임계값',
    chosen_option='0.35 확률 임계값',
    alternatives_considered=[
        '0.5 (균형잡힌)',
        '0.25 (더 공격적)',
        '세그먼트별 동적 임계값'
    ],
    rationale='비즈니스 비용 함수에 최적화: $50 유지 비용 vs $500 이탈 비용. 0.35는 예상 가치 최대화.',
    trade_offs='더 많은 위양성 (낭비된 유지 노력) 하지만 더 많은 진양성 포착. 순 EV 긍정적.'
)

print(f"✅ {len(log.decisions)}개 의사결정 로깅됨")
```

### 단계 4: 중요 가정 식별

```python
# 검증이 가장 시급한 가정 찾기
critical = log.get_critical_assumptions()

if critical:
    print(f"\n⚠️  {len(critical)}개 중요 가정이 검증 필요:\n")

    for assum in critical:
        print(f"#{assum['id']}: {assum['assumption']}")
        print(f"  신뢰도: {assum['confidence']}")
        print(f"  영향: {assum['impact_if_wrong']}")
        if assum['validation_plan']:
            print(f"  계획: {assum['validation_plan']}")
        print()
else:
    print("✅ 중요 미검증 가정 없음")
```

### 단계 5: 가정 검증

```python
# 분석이 진행되면서 가정 검증

# 가정 #1 검증
log.validate_assumption(
    assumption_id=1,
    validation_result='확인됨',
    notes='훈련 윈도우 외의 2024년 11월 데이터에서 모델 테스트. 성능 유지 (AUC 0.86 vs 0.87 훈련 시).'
)

# 가정 #2 검증
log.validate_assumption(
    assumption_id=2,
    validation_result='부분적으로 확인됨',
    notes='제품팀이 대부분의 누락 데이터가 실제 비활동 확인. 모바일 사용자의 추적 문제로 2% 엣지 케이스 발견. 필터 추가하여 제외.'
)

print("✅ 가정 검증 및 로깅됨")
```

### 단계 6: 위험 평가 생성

```python
def assess_assumption_risk(log):
    """
    가정에서 전체 위험 수량화
    """

    risk_scores = {
        ('high', 'critical'): 9,
        ('high', 'high'): 8,
        ('high', 'medium'): 6,
        ('medium', 'critical'): 7,
        ('medium', 'high'): 6,
        ('medium', 'medium'): 4,
        ('low', 'critical'): 5,
        ('low', 'high'): 4,
        ('low', 'medium'): 2
    }

    total_risk = 0
    risk_breakdown = []

    for assum in log.assumptions:
        if not assum['validated']:
            # 신뢰도 및 영향 파싱
            conf = assum['confidence']

            # 영향 파싱 (첫 단어 추출)
            impact = assum['impact_if_wrong'].split()[0].lower()
            if 'high' in impact or 'severe' in impact or 'critical' in impact:
                impact_level = 'high'
            elif 'medium' in impact or 'moderate' in impact:
                impact_level = 'medium'
            else:
                impact_level = 'medium'  # 기본값

            # 위험 계산
            risk = risk_scores.get((conf, impact_level), 3)
            total_risk += risk

            risk_breakdown.append({
                'assumption_id': assum['id'],
                'assumption': assum['assumption'][:50] + '...',
                'risk_score': risk,
                'confidence': conf,
                'impact': impact_level
            })

    # 전체 위험 평가
    avg_risk = total_risk / len(log.assumptions) if log.assumptions else 0

    print(f"\n📊 위험 평가:")
    print(f"  총 위험 점수: {total_risk}")
    print(f"  가정당 평균: {avg_risk:.1f}")

    if avg_risk < 3:
        print(f"  전체 위험: ✅ 낮음")
    elif avg_risk < 6:
        print(f"  전체 위험: ⚠️  중간")
    else:
        print(f"  전체 위험: 🔴 높음")

    # 상위 위험
    print(f"\n  상위 위험 기여도:")
    for item in sorted(risk_breakdown, key=lambda x: x['risk_score'], reverse=True)[:3]:
        print(f"    #{item['assumption_id']}: {item['assumption']} (점수: {item['risk_score']})")

    return total_risk, avg_risk, risk_breakdown

risk_total, risk_avg, risk_details = assess_assumption_risk(log)
```

### 단계 7: 문서 생성

```python
# 완전한 가정 로그 내보내기

# 마크다운 형식
markdown_doc = log.export_to_markdown()

# 파일로 저장
with open('assumptions_log.md', 'w') as f:
    f.write(markdown_doc)

# 구조화된 데이터도 저장
log.save('assumptions_log.json')

print("\n✅ 문서 생성됨:")
print("   📄 assumptions_log.md")
print("   📄 assumptions_log.json")

# 요약 섹션 출력
print("\n" + "="*60)
print(markdown_doc.split('---')[0])  # 요약 섹션 출력
```

### 단계 8: 가정 리뷰 체크리스트 생성

```python
def generate_review_checklist(log):
    """
    피어 리뷰용 체크리스트 생성
    """

    checklist = []

    # 누락 카테고리 확인
    categories_found = set(a['category'] for a in log.assumptions)
    expected_categories = ['data', 'business_logic', 'statistical', 'technical']

    missing = set(expected_categories) - categories_found
    if missing:
        checklist.append({
            'type': 'missing_category',
            'item': f'카테고리 {", ".join(missing)}에 문서화된 가정 없음',
            'action': '이 카테고리에 가정이 있는지 검토'
        })

    # 낮은 신뢰도, 높은 영향 가정 확인
    critical = log.get_critical_assumptions()
    if critical:
        for assum in critical:
            checklist.append({
                'type': 'critical_unvalidated',
                'item': f'가정 #{assum["id"]} 검증 안 됨',
                'action': f'검증: {assum["assumption"][:50]}'
            })

    # 모호한 근거 확인
    vague_keywords = ['reasonable', 'standard', 'typical', 'usually']
    for assum in log.assumptions:
        rationale_lower = assum['rationale'].lower()
        if any(word in rationale_lower for word in vague_keywords):
            checklist.append({
                'type': 'vague_rationale',
                'item': f'가정 #{assum["id"]}의 근거가 모호함',
                'action': '더 구체적인 정당화 제공'
            })

    # 검증 상태 확인
    unvalidated_pct = (len([a for a in log.assumptions if not a['validated']]) /
                      len(log.assumptions) * 100) if log.assumptions else 0

    if unvalidated_pct > 50:
        checklist.append({
            'type': 'low_validation',
            'item': f'{unvalidated_pct:.0f}%의 가정이 미검증',
            'action': '분석 확정 전 검증 우선순위'
        })

    # 체크리스트 출력
    if checklist:
        print("\n📋 리뷰 체크리스트:")
        for i, item in enumerate(checklist, 1):
            print(f"\n{i}. {item['item']}")
            print(f"   조치: {item['action']}")
    else:
        print("\n✅ 모든 검사 통과!")

    return checklist

review_items = generate_review_checklist(log)
```

## 문맥 검증

가정 로그 확정 전에 확인:
- [ ] 모든 주요 가정 카테고리 포함됨
- [ ] 근거가 구체적이고 방어 가능
- [ ] 영향 평가가 현실적
- [ ] 중요 가정에 검증 계획 있음
- [ ] 의사결정이 검토된 대안 문서화
- [ ] 로그가 피어 리뷰됨

## 출력 템플릿

```
# 가정 로그: 고객 이탈 예측 모델

**분석가:** 데이터 과학팀
**생성:** 2025-01-11
**마지막 업데이트:** 2025-01-11

---

## 요약

- 총 가정: 8
- 총 의사결정: 3
- 검증됨: 6/8
- ⚠️  중요 미검증: 1

---

## 가정

### 데이터

**#1: 최근 90일 데이터가 대표성 있음**

- **근거:** 최근 제품 변경과 계절 패턴 포함
- **신뢰도:** 중간
- **잘못될 경우 영향:** 모델이 향후 기간으로 일반화되지 않을 수 있음
- **검증됨:** ✅ 확인됨 - 홀드아웃 기간에 테스트됨
- **검증 계획:** 다른 시간 기간의 홀드아웃 데이터에서 테스트

**#2: 누락된 참여 데이터는 비활동**

- **근거:** 100개 샘플의 수동 검사로 확인
- **신뢰도:** 높음
- **잘못될 경우 영향:** 활성 사용자를 비활성으로 오분류. 영향받는 사용자의 <1%
- **검증됨:** ✅ 부분적으로 확인됨 - 엣지 케이스 필터 추가
- **검증 계획:** 제품팀과 함께 특정 사용자 ID 현지 확인

### 비즈니스 로직

**#3: 이탈 = 30일 활동 없음**

- **근거:** 이해관계자 요구사항, 청구 주기와 일치
- **신뢰도:** 높음
- **잘못될 경우 영향:** 낮음 - 이것은 필수 정의
- **검증됨:** ✅ 이해관계자에서 확인됨

### 통계

**#4: 기능은 독립적**

- **근거:** 상관관계 행렬 확인, 최대 상관관계 0.45
- **신뢰도:** 중간
- **잘못될 경우 영향:** 모델이 상관된 기능을 과가중할 수 있음
- **검증됨:** ❌ 아직 검증 안 됨
- **검증 계획:** PCA에서 성능 변화 확인

---

## 주요 의사결정

**의사결정 #1: 기능 선택**

- **선택:** 모든 참여 기능
- **검토된 대안:**
  - 핵심 기능만
  - 인구통계 포함
  - 외부 데이터 추가
- **근거:** 참여가 가장 예측력 있음. 개인 정보 우려.
- **거래 비용:** 더 많은 복잡성 하지만 더 나은 정확도

**의사결정 #2: 모델 알고리즘**

- **선택:** XGBoost
- **검토된 대안:**
  - 로지스틱 회귀
  - 랜덤 포레스트
  - 신경망
- **근거:** 최고 교차 검증 성능 (AUC 0.87)
- **거래 비용:** 덜 해석 가능 하지만 5% 정확도 향상

---

## 위험 평가

총 위험 점수: 24
전체 위험: ⚠️  중간

상위 위험:
1. #4: 기능 독립성 가정 (점수: 7)
2. #5: 정상성 가정 (점수: 6)

---

## 검증 상태

✅ 75% 검증됨 (6/8)
⚠️  1개 중요 가정 검증 보류 중
📅 다음 리뷰: 모델 배포 전
```

## 일반적인 시나리오

### 시나리오 1: "새 분석 시작 - 가정 추적 설정"
→ 가정 로그 초기화
→ 초기 가설 문서화
→ 검증 프레임워크 설정
→ 이해관계자와 공유
→ 분석이 진행되면서 업데이트

### 시나리오 2: "분석 피어 리뷰"
→ 가정 로그 검토
→ 모호한 근거에 질문
→ 누락된 가정 식별
→ 중요 가정 검증
→ 로그에 서명

### 시나리오 3: "분석 결과 예기치 않음"
→ 가정 검토
→ 어떤 것이 잘못되었을 수 있는지 식별
→ 의심스러운 가정 검증
→ 필요하면 분석 업데이트
→ 학습 문서화

### 시나리오 4: "규제/감사 요구사항"
→ 완전한 감시 추적 생성
→ 모든 의사결정 문서화
→ 검증 근거 표시
→ 엄격함 입증
→ 기록 유지

### 시나리오 5: "나중에 분석 재현"
→ 원래 가정 참조
→ 여전히 유효한지 확인
→ 새 문맥에 대해 업데이트
→ 결과 비교
→ 차이 문서화

## 누락된 문맥 처리

**사용자가 가정을 생각하지 못함:**
"어떤 가정을 하고 있을 수 있는지 식별하는 데 도움을 드리겠습니다:
- 데이터: 샘플이 대표성 있나요?
- 비즈니스: 핵심 개념을 어떻게 정의하나요?
- 통계: 어떤 분포를 가정하나요?
- 기술: 시스템 한계가 있나요?

체계적으로 살펴봅시다."

**사용자가 '가정 없음' 말함:**
"모든 분석에 가정이 있습니다! 일반적인 것:
- 데이터가 완전하고 정확
- 과거 패턴이 미래 예측
- 샘플이 모집단 대표
- 상관관계가 의미 있음

명시적으로 만들어봅시다."

**사용자가 명백한 가정만 나열:**
"좋은 시작입니다! 또한 문서화해봅시다:
- 수립한 선택 (이 방법 vs 다른 것?)
- 처리하는 엣지 케이스
- 포함하지 않는 것
- 시간/자원 제약

이것도 가정입니다!"

**사용자가 신뢰도 수준 확실하지 않음:**
"평가해봅시다:
- 검증했나요? (높은 신뢰도)
- 도메인 지식 기반인가? (중간)
- 그냥 합리적으로 보임? (낮음)

정직함이 검증 우선순위 정하는 데 도움이 됩니다."

## 고급 옵션

기본 로그 후 제공:

**자동 가정 감지**:
"코드/쿼리를 스캔하여 놓쳤을 암시적 가정 식별할 수 있습니다."

**가정 검증 프레임워크**:
"가정이 유효하지 않아지면 경고하는 자동 테스트 설정 (예: 데이터 분포 변화)."

**민감성 분석**:
"각 가정이 위반될 경우 결과가 얼마나 변하는지 정량화."

**가정 의존성**:
"어떤 가정이 다른 것에 의존하는지 매핑 - 연쇄 위험 이해에 도움."

**역사적 가정 추적**:
"여러 분석에서 가정을 추적하여 패턴 식별 및 향후 작업 개선."

**가정 리뷰 템플릿**:
"가정 검증에 초점을 맞춘 피어 리뷰용 템플릿 생성."
