---
name: visualization-builder
description: 효과적이고 출판 품질의 데이터 시각화를 만드세요. Create effective, publication-ready data visualizations. Use when choosing chart types, designing dashboards, creating presentation visuals, or building interactive visualizations with best practices.
---

# 시각화 빌더(Visualization Builder)

## 단계(Phase)
Phase 6 — 시각화 및 전달

## 입력(Input)
- 이전 스킬: Phase 4 분석 스킬들 + insight-synthesis
- 받는 파일: Phase 4의 `*_result.csv` + `insight-synthesis_report.md`

## 출력(Output)
- `visualization-builder.ipynb`
- `visualization-builder_result.csv`
- `visualization-builder_report.md`

## 빠른 시작(Quick Start)

시각화 모범 사례와 적절한 차트 선택을 사용하여 인사이트(Insight)를 효과적으로 전달하는 명확하고 영향력 있는 데이터 시각화를 만드세요.

## 컨텍스트 요구사항(Context Requirements)

1. **데이터(Data)**: 시각화할 데이터
2. **메시지(Message)**: 전달할 핵심 인사이트
3. **대상(Audience)**: 기술 관련자 vs 비즈니스 이해관계자, 필요한 상세 수준
4. **매체(Medium)**: 대시보드(Dashboard), 프레젠테이션, 리포트, 인터랙티브
5. **브랜드(Brand)**: 색상, 스타일 지침

## 컨텍스트 수집(Context Gathering)

### 데이터(For Data)를 위해:
"어떤 데이터를 시각화하고 계신가요?
- 변수(범주형, 연속형, 시간)
- 표본 크기 및 세분화 수준
- 필요한 비교(범주, 기간, 세그먼트)

예시: '월별 수익(매월 12개월, 5개 카테고리별)'"

### 메시지(For Message)를 위해:
"핵심 요점은 무엇인가요?
- 시간 경과에 따른 추세?
- 그룹 간 비교?
- 구성/분해?
- 관계/상관관계?
- 분포?

명확한 메시지 → 올바른 차트 유형."

### 대상(For Audience)을 위해:
"누가 이것을 볼 건가요?
- **기술 관련자**: 복잡성을 처리할 수 있고, 상세함을 좋아함
- **임원진**: 단순성이 필요, 인사이트에 초점
- **일반 대중**: 자체 설명 가능한 디자인 필요

대상이 상세 수준과 주석 필요성을 결정합니다."

## 워크플로우(Workflow)

### 단계 1: 차트 유형 선택(Choose Chart Type)

```python
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

def recommend_chart_type(data_type, message_type):
    """Recommend appropriate visualization"""
    
    recommendations = {
        ('time_series', 'trend'): 'Line chart',
        ('categories', 'comparison'): 'Bar chart (horizontal if many categories)',
        ('categories', 'composition'): 'Stacked bar or pie chart',
        ('two_variables', 'relationship'): 'Scatter plot',
        ('distribution', 'single'): 'Histogram or box plot',
        ('distribution', 'multiple'): 'Violin plot or overlaid histograms',
        ('geographic', 'comparison'): 'Choropleth map',
        ('hierarchical', 'composition'): 'Treemap or sunburst',
        ('flow', 'process'): 'Sankey diagram'
    }
    
    chart = recommendations.get((data_type, message_type))
    
    print(f"📊 Recommended Chart: {chart}")
    print(f"   For: {message_type} of {data_type}")
    
    return chart

# Example
recommend_chart_type('time_series', 'trend')
```

### 단계 2: 출판 품질 시각화 설계(Design Publication-Quality Visualization)

```python
def create_professional_chart(df, title, y_label):
    """Create polished, publication-ready chart"""
    
    # Set style
    sns.set_style("whitegrid")
    plt.rcParams['font.family'] = 'sans-serif'
    plt.rcParams['font.size'] = 11
    
    fig, ax = plt.subplots(figsize=(12, 6))
    
    # Plot data
    colors = ['#2E86AB', '#A23B72', '#F18F01', '#C73E1D', '#6A994E']
    
    for i, col in enumerate(df.columns[1:]):
        ax.plot(df['date'], df[col], 
               marker='o', linewidth=2.5, 
               markersize=6, color=colors[i % len(colors)],
               label=col)
    
    # Styling
    ax.set_title(title, fontsize=16, fontweight='bold', pad=20)
    ax.set_xlabel('', fontsize=12)
    ax.set_ylabel(y_label, fontsize=12)
    
    # Grid
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.set_axisbelow(True)
    
    # Legend
    ax.legend(frameon=True, loc='best', fontsize=10)
    
    # Format y-axis
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'${x/1000:.0f}K'))
    
    # Annotations for key points
    max_idx = df[df.columns[1]].idxmax()
    max_val = df[df.columns[1]].max()
    ax.annotate(f'Peak: ${max_val/1000:.0f}K',
               xy=(df.loc[max_idx, 'date'], max_val),
               xytext=(10, 10), textcoords='offset points',
               fontsize=10, bbox=dict(boxstyle='round', fc='white', alpha=0.8),
               arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
    
    plt.tight_layout()
    return fig

# Example data
dates = pd.date_range('2024-01-01', periods=12, freq='M')
data = pd.DataFrame({
    'date': dates,
    'Product A': np.random.randint(80, 120, 12) * 1000,
    'Product B': np.random.randint(60, 100, 12) * 1000
})

fig = create_professional_chart(data, 'Monthly Revenue by Product', 'Revenue')
plt.savefig('revenue_chart.png', dpi=300, bbox_inches='tight')
print("✅ Professional chart created")
```

### 단계 3: 시각 설계 원칙 적용(Apply Visual Design Principles)

```python
def apply_visual_hierarchy(ax, focus_element=None):
    """Emphasize key elements, de-emphasize secondary"""
    
    # De-emphasize gridlines
    ax.grid(True, alpha=0.2, color='gray', linestyle=':')
    
    # Emphasize focus element
    if focus_element:
        # Make other elements semi-transparent
        for line in ax.get_lines():
            if line.get_label() != focus_element:
                line.set_alpha(0.3)
                line.set_linewidth(1.5)
            else:
                line.set_linewidth(3)
                line.set_zorder(10)
    
    # Clean spines
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#333333')
    ax.spines['bottom'].set_color('#333333')
    
    return ax

print("✅ Visual hierarchy principles applied")
```

### 단계 4: 컨텍스트 및 주석 추가(Add Context and Annotations)

```python
def add_contextual_annotations(ax, insights, benchmarks=None):
    """Add explanatory text and reference lines"""
    
    # Add insight callouts
    for insight in insights:
        ax.annotate(
            insight['text'],
            xy=insight['position'],
            xytext=insight['text_position'],
            fontsize=9,
            bbox=dict(boxstyle='round,pad=0.5', fc='yellow', alpha=0.3),
            arrowprops=dict(arrowstyle='->', lw=1.5)
        )
    
    # Add benchmark lines
    if benchmarks:
        for benchmark in benchmarks:
            ax.axhline(benchmark['value'], 
                      color='red', linestyle='--', alpha=0.5,
                      label=benchmark['label'])
    
    # Add source
    fig = ax.get_figure()
    fig.text(0.99, 0.01, 'Source: Analytics Database | Generated: Jan 2025',
            ha='right', va='bottom', fontsize=8, color='gray')
    
    return ax

# Example usage
insights = [
    {
        'text': 'Holiday spike',
        'position': (dates[10], data['Product A'].iloc[10]),
        'text_position': (10, 20)
    }
]

benchmarks = [
    {'value': 90000, 'label': 'Target: $90K'}
]

print("✅ Contextual annotations added")
```

### 단계 5: 대시보드 레이아웃 생성(Create Dashboard Layout)

```python
def create_dashboard_layout(metrics_dict):
    """Multi-panel dashboard with proper spacing"""
    
    fig = plt.figure(figsize=(16, 10))
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
    
    # Large chart top left
    ax1 = fig.add_subplot(gs[0:2, 0:2])
    ax1.set_title('Primary Metric Trend', fontsize=14, fontweight='bold')
    
    # Supporting charts
    ax2 = fig.add_subplot(gs[0, 2])
    ax2.set_title('Breakdown', fontsize=12)
    
    ax3 = fig.add_subplot(gs[1, 2])
    ax3.set_title('Comparison', fontsize=12)
    
    # KPI cards at bottom
    ax4 = fig.add_subplot(gs[2, 0])
    ax5 = fig.add_subplot(gs[2, 1])
    ax6 = fig.add_subplot(gs[2, 2])
    
    # Style KPI cards
    for ax, (metric, value) in zip([ax4, ax5, ax6], metrics_dict.items()):
        ax.text(0.5, 0.6, f"${value:,.0f}", 
               ha='center', va='center', fontsize=24, fontweight='bold')
        ax.text(0.5, 0.3, metric,
               ha='center', va='center', fontsize=12, color='gray')
        ax.axis('off')
        ax.set_facecolor('#f8f9fa')
    
    return fig, [ax1, ax2, ax3, ax4, ax5, ax6]

metrics = {'Revenue': 125000, 'Customers': 450, 'AOV': 278}
fig, axes = create_dashboard_layout(metrics)
plt.savefig('dashboard.png', dpi=300, bbox_inches='tight')
print("✅ Dashboard layout created")
```

## 컨텍스트 검증(Context Validation)

- [ ] 차트 유형이 데이터 및 메시지와 일치
- [ ] 축이 명확하게 표시됨
- [ ] 범례가 읽기 쉬움
- [ ] 핵심 인사이트에 주석이 있음
- [ ] 색상이 접근성 있음(색맹-안전)
- [ ] 출처 인용됨

## 출력 템플릿(Output Template)

```
[다음을 포함한 전문적인 시각화:]

✓ 명확한 제목
✓ 단위가 있는 명확한 축
✓ 적절한 스케일
✓ 범례(여러 계열인 경우)
✓ 핵심 포인트에 주석
✓ 관련이 있으면 벤치마크 라인
✓ 출처 표시
✓ 고해상도 내보내기(300 DPI)
✓ 색맹-친화적 팔레트
✓ 일관된 브랜드 스타일
```

## 일반적인 시나리오(Common Scenarios)

### 시나리오 1: "임원진 프레젠테이션 시각 만들기"
→ 간단하고 영향력 있는 차트
→ 핵심 인사이트에 주석
→ 브랜드 색상 사용
→ 큰 글꼴, 최소한의 상세
→ 차트당 하나의 메시지

### 시나리오 2: "인터랙티브 대시보드 구축"
→ 계층적 레이아웃(주요 + 보조)
→ 패널 전체에서 일관된 스타일
→ 명확한 네비게이션
→ 반응형 디자인
→ 성능 최적화

### 시나리오 3: "그룹 간 비교 표시"
→ 그룹화된/클러스터된 막대 사용
→ 논리적 순서(알파벳순, 값 순)
→ 그룹당 일관된 색상
→ 직접 레이블 vs 범례
→ 가장 큰 차이 강조

### 시나리오 4: "계절성이 있는 시계열 표시"
→ 추세선이 있는 선 차트
→ 계절성 분해 추가
→ 주요 이벤트에 주석
→ 신뢰 대역 표시
→ 년 대 년 비교 포함

### 시나리오 5: "복잡한 관계 시각화"
→ 산점도로 시작
→ 추세선 추가
→ 3번째 변수를 크기/색상으로 인코딩
→ 핵심 세그먼트로 필터링
→ 가능하면 인터랙티브 탐색

## 누락된 컨텍스트 처리(Handling Missing Context)

**사용자가 "좋게 보이도록"이라고 말하는 경우:**
"구체적인 정보가 필요합니다:
- 핵심 메시지가 무엇인가요?
- 대상이 누구인가요?
- 이것이 어디에 표시될 건가요?
- 브랜드 지침이 있나요?
이것들이 디자인 선택을 결정합니다."

**불명확한 차트 유형:**
"함께 결정해봅시다:
- 값을 비교하고 있나요? → 막대 차트
- 시간 경과에 따른 추세를 보고 있나요? → 선 차트
- 구성을 표시하고 있나요? → 누적 막대/원형
- 관계를 표시하고 있나요? → 산점도
어떤 유형의 질문에 답하고 있나요?"

**한 차트에 너무 많은 데이터:**
"초점을 맞춰봅시다:
- #1 인사이트가 무엇인가요?
- 핵심 세그먼트로 필터링할 수 있나요?
- 대신 대시보드여야 하나요?
- 부록에 무엇을 넣을 수 있나요?
명확성을 위해서는 적을수록 좋습니다."

## 고급 옵션(Advanced Options)

**인터랙티브 시각화**: Plotly, Altair 웹 기반 탐색용

**애니메이션**: 애니메이션 전환으로 시간 경과에 따른 변화 표시

**소규모 배수**: 비교를 위해 차트 구조 반복

**접근성**: Alt 텍스트, 색상 외에 패턴, 스크린 리더 호환

**자동화된 차트 생성**: 데이터에서 템플릿 기반 차트 생성
