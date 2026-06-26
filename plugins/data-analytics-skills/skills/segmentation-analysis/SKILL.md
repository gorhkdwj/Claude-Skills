---
name: segmentation-analysis
description: 실행 가능한 인사이트를 갖춘 고객/사용자 세분화를 수행합니다. 고객 그룹을 식별하거나, 세그먼트별 행동을 분석하거나, 고가치 세그먼트를 프로파일링하거나, 세분화 가설을 테스트할 때 사용합니다. | Customer/user segmentation with actionable insights. Use when identifying distinct customer groups, analyzing segment-specific behavior, profiling high-value segments, or testing segmentation hypotheses.
---

# 세분화 분석

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## Input
- 이전 스킬: programmatic-eda + data-quality-audit + semantic-model-builder + analysis-assumptions-log
- 받는 파일: `programmatic-eda_result.csv` + `data-quality-audit_result.csv` + `semantic-model-builder_report.md` + `analysis-assumptions-log_report.md`

## Output
- `segmentation-analysis.ipynb`
- `segmentation-analysis_result.csv`
- `segmentation-analysis_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## 빠른 시작

데이터 기반 클러스터링 또는 규칙 기반 세분화를 통해 의미 있는 사용자 세그먼트를 식별하고, 각 세그먼트를 프로파일링하며, 타겟팅된 전략을 위한 실행 가능한 인사이트를 생성하세요.

## 컨텍스트 요구사항

세그먼트를 분석하기 전에 필요한 사항:

1. **사용자 데이터**: 속성과 행동이 포함된 개인 수준 데이터
2. **세분화 접근법**: 클러스터링(데이터 기반) vs 규칙 기반(비즈니스 로직)
3. **핵심 변수**: 세그먼트를 정의하는 속성/행동
4. **비즈니스 컨텍스트**: 세분화가 어떤 의사결정을 알릴 것인지
5. **기존 세그먼트** (선택): 검증 또는 개선할 현재 세분화

## 컨텍스트 수집

### 사용자 데이터의 경우:
"사용자가 누구이고 무엇을 하는지 보여주는 사용자 수준 데이터가 필요합니다:

**인구통계/속성:**
- 사용자 ID, 가입 날짜, 위치, 요금제 유형 등

**행동 데이터:**
- 구매 이력, 참여 지표, 기능 사용
- 예: 'sessions_per_month', 'revenue_lifetime', 'last_active_date'

**포맷 옵션:**
```
user_id | age | plan  | monthly_spend | sessions_month | ...
12345   | 32  | pro   | 99.00         | 45             | ...
```

사용할 수 있는 사용자 데이터는 무엇입니까?"

### 세분화 접근법의 경우:
"사용자를 어떻게 세분화하고 싶습니까?

**옵션 1 - 데이터 기반(클러스터링):**
- 데이터가 자연적인 그룹을 드러나게 하기
- K-means, 계층적 클러스터링 등
- 미리 세그먼트를 모를 때 적합
- 예: '5가지 뚜렷한 사용자 유형 찾기'

**옵션 2 - 규칙 기반(비즈니스 로직):**
- 특정 규칙으로 세그먼트 정의
- 도메인 지식 기반
- 가설이 있을 때 적합
- 예: '헤비 사용자: >20 세션/월, 라이트: <5'

**옵션 3 - RFM(최근성, 빈도, 금전성):**
- 클래식 전자상거래 세분화
- 구매 행동 기반
- '챔피언', '위험' 등의 세그먼트 생성

어느 접근법이 귀하의 필요에 맞습니까?"

### 핵심 변수의 경우:
"세분화에 가장 중요한 속성/행동은 무엇입니까?

**참여 변수:**
- 로그인 빈도, 세션 지속 시간
- 기능 사용 패턴
- 콘텐츠 소비

**가치 변수:**
- 수익, LTV, 평균 주문 값
- 요금제 유형, 구독 계층

**라이프사이클 변수:**
- 가입 이후 일수, 코호트
- 활성화 상태, 이탈 위험

**인구통계 변수:**
- 산업, 회사 규모, 역할
- 지역, 디바이스 선호도

의미 있는 세분화를 위해 3-7개의 가장 중요한 변수를 선택하세요."

### 비즈니스 컨텍스트의 경우:
"이 세그먼트로 무엇을 할 것입니까?

**일반적인 사용 사례:**
- **제품 개발**: 고가치 세그먼트의 우선순위 기능
- **마케팅**: 타겟팅된 메시징 및 캠페인
- **가격 책정**: 다양한 세그먼트를 위한 커스텀 플랜
- **유지**: 세그먼트별 참여 전략
- **영업**: 고객 유형별 접근 방식 맞춤화

목표를 알면 실행 가능한 세그먼트를 만드는 데 도움이 됩니다."

### 검증의 경우:
"비교할 기존 세그먼트가 있습니까?

있다면:
- 현재 세그먼트가 뚜렷한지 검증할 수 있습니다
- 현재 세분화의 겹침/격차 표시
- 개선 사항 제안

없다면:
- 처음부터 세그먼트를 만들겠습니다
- 비즈니스 로직 검사로 검증"

## 워크플로우

### 1단계: 데이터 로드 및 탐색

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from scipy.cluster.hierarchy import dendrogram, linkage
from scipy.spatial.distance import pdist

# Load user data
users = pd.read_csv('user_data.csv')

print(f"📊 User Data Loaded:")
print(f"  Total Users: {len(users):,}")
print(f"  Features: {len(users.columns)}")
print(f"\n  Columns: {users.columns.tolist()}")

# Check for missing values
missing = users.isnull().sum()
if missing.sum() > 0:
    print(f"\n⚠️  Missing Values:")
    print(missing[missing > 0])
```

**검사점**: "데이터가 로드되었습니다. 세분화 변수를 선택할 준비가 되었습니까?"

### 2단계: 세분화 변수 선택 및 준비

```python
# Define segmentation variables
segment_vars = [
    'monthly_sessions',
    'total_revenue',
    'days_since_signup',
    'feature_adoption_score',
    'support_tickets'
]

# Create clean dataset
df_segment = users[['user_id'] + segment_vars].copy()

# Handle missing values
df_segment = df_segment.dropna()

# Remove outliers (optional - use with caution)
def remove_outliers_iqr(df, columns):
    """Remove outliers using IQR method"""
    df_clean = df.copy()
    for col in columns:
        Q1 = df_clean[col].quantile(0.25)
        Q3 = df_clean[col].quantile(0.75)
        IQR = Q3 - Q1
        lower = Q1 - 1.5 * IQR
        upper = Q3 + 1.5 * IQR
        df_clean = df_clean[(df_clean[col] >= lower) & (df_clean[col] <= upper)]
    return df_clean

df_segment = remove_outliers_iqr(df_segment, segment_vars)

print(f"\n📋 Segmentation Dataset:")
print(f"  Users: {len(df_segment):,}")
print(f"  Variables: {segment_vars}")
print(f"\n  Summary Statistics:")
print(df_segment[segment_vars].describe())

# Standardize features (important for clustering)
scaler = StandardScaler()
df_scaled = pd.DataFrame(
    scaler.fit_transform(df_segment[segment_vars]),
    columns=segment_vars,
    index=df_segment.index
)
```

### 3단계: 최적 세그먼트 수 결정

```python
def find_optimal_clusters(df_scaled, max_k=10):
    """
    Use elbow method and silhouette score to find optimal k
    """
    from sklearn.metrics import silhouette_score
    
    inertias = []
    silhouettes = []
    K_range = range(2, max_k + 1)
    
    for k in K_range:
        kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
        kmeans.fit(df_scaled)
        inertias.append(kmeans.inertia_)
        silhouettes.append(silhouette_score(df_scaled, kmeans.labels_))
    
    # Plot results
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # Elbow plot
    ax1.plot(K_range, inertias, marker='o')
    ax1.set_xlabel('Number of Clusters (k)')
    ax1.set_ylabel('Inertia (Within-Cluster Sum of Squares)')
    ax1.set_title('Elbow Method for Optimal k')
    ax1.grid(True, alpha=0.3)
    
    # Silhouette plot
    ax2.plot(K_range, silhouettes, marker='o', color='green')
    ax2.set_xlabel('Number of Clusters (k)')
    ax2.set_ylabel('Silhouette Score')
    ax2.set_title('Silhouette Score by k (higher is better)')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('optimal_clusters.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Recommend k
    best_k = K_range[np.argmax(silhouettes)]
    print(f"\n📊 Optimal Clusters Analysis:")
    print(f"  Recommended k: {best_k} (highest silhouette score)")
    print(f"  Silhouette scores: {dict(zip(K_range, [f'{s:.3f}' for s in silhouettes]))}")
    
    return best_k

optimal_k = find_optimal_clusters(df_scaled, max_k=8)
```

**검사점**: "분석에 따르면 {optimal_k}개의 세그먼트가 비즈니스 관점에서 타당합니까? 다른 수를 선호하십니까?"

### 4단계: 세그먼트 생성(K-평균 클러스터링)

```python
# Run K-means with optimal k
n_clusters = optimal_k  # or user-specified

kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
df_segment['segment'] = kmeans.fit_predict(df_scaled)

print(f"\n✅ Segmentation Complete:")
print(f"  Created {n_clusters} segments")
print(f"\n  Segment Distribution:")
print(df_segment['segment'].value_counts().sort_index())
```

### 5단계: 각 세그먼트 프로파일링

```python
def profile_segments(df_segment, segment_vars):
    """
    Create detailed profiles for each segment
    """
    
    profiles = []
    
    for seg_id in sorted(df_segment['segment'].unique()):
        seg_data = df_segment[df_segment['segment'] == seg_id]
        
        profile = {
            'segment_id': seg_id,
            'size': len(seg_data),
            'pct_of_total': len(seg_data) / len(df_segment) * 100
        }
        
        # Calculate mean for each variable
        for var in segment_vars:
            profile[f'{var}_mean'] = seg_data[var].mean()
            profile[f'{var}_median'] = seg_data[var].median()
        
        profiles.append(profile)
    
    df_profiles = pd.DataFrame(profiles)
    
    # Calculate relative importance (vs overall average)
    for var in segment_vars:
        overall_mean = df_segment[var].mean()
        df_profiles[f'{var}_vs_avg'] = (
            (df_profiles[f'{var}_mean'] - overall_mean) / overall_mean * 100
        )
    
    return df_profiles

profiles = profile_segments(df_segment, segment_vars)

print(f"\n📊 Segment Profiles:\n")
print(profiles.to_string(index=False))
```

### 6단계: 세그먼트 이름 지정 및 해석

```python
def name_segments(profiles, segment_vars):
    """
    Assign meaningful names based on segment characteristics
    """
    
    segment_names = {}
    
    for _, row in profiles.iterrows():
        seg_id = int(row['segment_id'])
        
        # Identify defining characteristics
        characteristics = []
        
        for var in segment_vars:
            vs_avg = row[f'{var}_vs_avg']
            
            if abs(vs_avg) > 50:  # 50% above/below average
                direction = "High" if vs_avg > 0 else "Low"
                characteristics.append(f"{direction} {var.replace('_', ' ').title()}")
        
        # Create name
        if not characteristics:
            name = f"Average Users"
        else:
            name = " & ".join(characteristics[:2])  # Use top 2 characteristics
        
        segment_names[seg_id] = name
        
        print(f"\nSegment {seg_id}: {name}")
        print(f"  Size: {row['size']:,} users ({row['pct_of_total']:.1f}%)")
        print(f"  Key Characteristics:")
        for var in segment_vars:
            mean_val = row[f'{var}_mean']
            vs_avg = row[f'{var}_vs_avg']
            print(f"    • {var}: {mean_val:.1f} ({vs_avg:+.0f}% vs avg)")
    
    return segment_names

segment_names = name_segments(profiles, segment_vars)

# Add names to segment data
df_segment['segment_name'] = df_segment['segment'].map(segment_names)
```

### 7단계: 세그먼트 시각화

```python
def visualize_segments(df_segment, df_scaled, segment_vars):
    """
    Create comprehensive segment visualizations
    """
    
    # PCA for 2D visualization
    pca = PCA(n_components=2)
    pca_result = pca.fit_transform(df_scaled)
    
    fig = plt.figure(figsize=(16, 10))
    
    # Plot 1: PCA scatter
    ax1 = plt.subplot(2, 3, 1)
    scatter = ax1.scatter(pca_result[:, 0], pca_result[:, 1], 
                         c=df_segment['segment'], cmap='viridis', alpha=0.6)
    ax1.set_xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.1%} variance)')
    ax1.set_ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.1%} variance)')
    ax1.set_title('Segment Distribution (PCA)')
    plt.colorbar(scatter, ax=ax1, label='Segment')
    
    # Plot 2: Segment sizes
    ax2 = plt.subplot(2, 3, 2)
    segment_counts = df_segment['segment_name'].value_counts()
    ax2.barh(range(len(segment_counts)), segment_counts.values)
    ax2.set_yticks(range(len(segment_counts)))
    ax2.set_yticklabels(segment_counts.index)
    ax2.set_xlabel('Number of Users')
    ax2.set_title('Segment Sizes')
    
    for i, v in enumerate(segment_counts.values):
        ax2.text(v, i, f' {v:,}', va='center')
    
    # Plot 3-5: Key variables by segment
    for idx, var in enumerate(segment_vars[:3], start=3):
        ax = plt.subplot(2, 3, idx)
        
        data_by_segment = [df_segment[df_segment['segment'] == seg][var].values 
                          for seg in sorted(df_segment['segment'].unique())]
        
        ax.boxplot(data_by_segment, labels=[segment_names[i] 
                   for i in sorted(df_segment['segment'].unique())])
        ax.set_ylabel(var.replace('_', ' ').title())
        ax.set_title(f'{var.replace("_", " ").title()} by Segment')
        ax.tick_params(axis='x', rotation=45)
    
    # Plot 6: Radar chart
    ax6 = plt.subplot(2, 3, 6, projection='polar')
    
    # Normalize profiles for radar chart
    angles = np.linspace(0, 2 * np.pi, len(segment_vars), endpoint=False).tolist()
    angles += angles[:1]
    
    for seg_id in sorted(df_segment['segment'].unique()):
        seg_data = df_segment[df_segment['segment'] == seg_id]
        values = [seg_data[var].mean() / df_segment[var].max() 
                 for var in segment_vars]
        values += values[:1]
        
        ax6.plot(angles, values, 'o-', linewidth=2, 
                label=segment_names[seg_id])
        ax6.fill(angles, values, alpha=0.15)
    
    ax6.set_xticks(angles[:-1])
    ax6.set_xticklabels([var.replace('_', ' ').title() for var in segment_vars])
    ax6.set_title('Segment Profiles (Normalized)')
    ax6.legend(loc='upper right', bbox_to_anchor=(1.3, 1.0))
    
    plt.tight_layout()
    plt.savefig('segment_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()

visualize_segments(df_segment, df_scaled, segment_vars)
```

### 8단계: 실행 가능한 인사이트 생성

```python
def generate_segment_insights(df_segment, profiles, segment_names):
    """
    Create actionable recommendations for each segment
    """
    
    print(f"\n{'='*70}")
    print("💡 ACTIONABLE INSIGHTS BY SEGMENT")
    print('='*70)
    
    # Identify high-value segments
    if 'total_revenue' in df_segment.columns:
        segment_revenue = df_segment.groupby('segment')['total_revenue'].sum().sort_values(ascending=False)
        top_revenue_seg = segment_revenue.index[0]
        
        print(f"\n🏆 HIGHEST VALUE SEGMENT: {segment_names[top_revenue_seg]}")
        print(f"  Revenue: ${segment_revenue.iloc[0]:,.0f}")
        print(f"  Size: {len(df_segment[df_segment['segment'] == top_revenue_seg]):,} users")
        print(f"  Action: Prioritize retention and expansion for this segment")
    
    # Identify growth opportunity segments
    if 'monthly_sessions' in df_segment.columns:
        for seg_id, name in segment_names.items():
            seg_data = df_segment[df_segment['segment'] == seg_id]
            
            print(f"\n📊 {name}:")
            print(f"  Size: {len(seg_data):,} users")
            
            # Characterize segment
            if 'total_revenue' in seg_data.columns:
                avg_revenue = seg_data['total_revenue'].mean()
                print(f"  Avg Revenue: ${avg_revenue:.2f}")
            
            engagement = seg_data['monthly_sessions'].mean()
            print(f"  Avg Sessions: {engagement:.1f}/month")
            
            # Recommendations
            print(f"  Recommended Actions:")
            
            if engagement > df_segment['monthly_sessions'].mean() * 1.5:
                print(f"    ✓ High engagement - Focus on monetization")
                print(f"    ✓ Test premium features/upsells")
            elif engagement < df_segment['monthly_sessions'].mean() * 0.5:
                print(f"    ⚠️  Low engagement - Focus on activation")
                print(f"    ✓ Onboarding improvements")
                print(f"    ✓ Re-engagement campaigns")
            else:
                print(f"    ✓ Moderate engagement - Growth opportunity")
                print(f"    ✓ Feature education")
                print(f"    ✓ Use case expansion")

generate_segment_insights(df_segment, profiles, segment_names)
```

### 9단계: 세그먼트 전략 매트릭스 생성

```python
def create_strategy_matrix(profiles, segment_names):
    """
    Map segments to recommended strategies
    """
    
    strategies = []
    
    for seg_id, name in segment_names.items():
        profile = profiles[profiles['segment_id'] == seg_id].iloc[0]
        
        # Determine strategy based on profile
        if 'total_revenue_mean' in profile:
            revenue = profile['total_revenue_mean']
            engagement = profile.get('monthly_sessions_mean', 0)
            
            if revenue > profiles['total_revenue_mean'].mean():
                if engagement > profiles.get('monthly_sessions_mean', pd.Series([0])).mean():
                    strategy = "Retain & Expand"
                    priority = "High"
                else:
                    strategy = "Re-engage"
                    priority = "Medium"
            else:
                if engagement > profiles.get('monthly_sessions_mean', pd.Series([0])).mean():
                    strategy = "Monetize"
                    priority = "High"
                else:
                    strategy = "Activate or Sunset"
                    priority = "Low"
        else:
            strategy = "Analyze Further"
            priority = "Medium"
        
        strategies.append({
            'segment': name,
            'size': int(profile['size']),
            'strategy': strategy,
            'priority': priority
        })
    
    df_strategy = pd.DataFrame(strategies)
    
    print(f"\n{'='*70}")
    print("📋 SEGMENT STRATEGY MATRIX")
    print('='*70)
    print(df_strategy.to_string(index=False))
    
    return df_strategy

strategy_matrix = create_strategy_matrix(profiles, segment_names)

# Save results
df_segment.to_csv('user_segments.csv', index=False)
profiles.to_csv('segment_profiles.csv', index=False)
strategy_matrix.to_csv('segment_strategies.csv', index=False)
```

## 컨텍스트 검증

진행하기 전에 확인:
- [ ] 관련 변수가 있는 충분한 사용자 수준 데이터 확보
- [ ] 세분화 변수가 깔끔하고 의미 있음
- [ ] 샘플 크기가 클러스터링에 적합 (예상 세그먼트당 최소 100명 사용자)
- [ ] 세그먼트 해석을 위한 비즈니스 컨텍스트 이해
- [ ] 세분화 접근법에 대한 이해관계자 지원 확보

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENTATION ANALYSIS REPORT
User Base: 50,000 customers
Analysis Date: January 11, 2025
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SEGMENTS IDENTIFIED: 5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENT 1: Power Users
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Size: 8,500 users (17%)

Profile:
  • Monthly Sessions: 45 (+180% vs avg)
  • Total Revenue: $1,250 (+220% vs avg)
  • Feature Adoption: 85% (+95% vs avg)
  • Support Tickets: 2 (-33% vs avg)

Characteristics:
  ✓ Highly engaged across all features
  ✓ Highest revenue contribution (45% of total)
  ✓ Low support needs
  ✓ Strong product advocates

Recommended Strategy:
  Priority: HIGH
  Focus: Retention & Expansion
  
  Actions:
  1. VIP program with dedicated support
  2. Beta access to new features
  3. Referral incentives
  4. Advocacy/community leadership
  
  Risk: High churn impact - monitor closely

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENT 2: Growth Potential
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Size: 15,000 users (30%)

Profile:
  • Monthly Sessions: 12 (-25% vs avg)
  • Total Revenue: $450 (+15% vs avg)
  • Feature Adoption: 35% (-20% vs avg)
  • Support Tickets: 4 (+33% vs avg)

Characteristics:
  ✓ Willing to pay but under-engaged
  ✓ Using only core features
  ✓ Higher support needs

Recommended Strategy:
  Priority: HIGH
  Focus: Feature Education & Engagement
  
  Actions:
  1. Onboarding optimization
  2. Feature discovery campaigns
  3. Use case webinars
  4. In-app guidance improvements
  
  Opportunity: +$200/user if engaged like Segment 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENT 3: Free Riders
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Size: 12,000 users (24%)

Profile:
  • Monthly Sessions: 8 (-50% vs avg)
  • Total Revenue: $0 (-100% vs avg)
  • Feature Adoption: 25% (-43% vs avg)
  • Days Since Signup: 180 (+125% vs avg)

Characteristics:
  ✓ Long-term free tier users
  ✓ Minimal engagement
  ✓ Not converting to paid

Recommended Strategy:
  Priority: MEDIUM
  Focus: Monetization or Graduation
  
  Actions:
  1. Freemium limit enforcement
  2. Value demonstration campaigns
  3. Upgrade incentives
  4. Or: Accept as brand awareness
  
  Decision Point: Monetize or reduce support costs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENT 4: At Risk
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Size: 6,500 users (13%)

Profile:
  • Monthly Sessions: 2 (-88% vs avg)
  • Total Revenue: $300 (-23% vs avg)
  • Days Since Last Active: 45 (+350% vs avg)
  • Feature Adoption: 20% (-54% vs avg)

Characteristics:
  ⚠️  Dramatically declining engagement
  ⚠️  Still paying but not using product
  ⚠️  High churn risk

Recommended Strategy:
  Priority: HIGH
  Focus: Win-Back & Retention
  
  Actions:
  1. IMMEDIATE: Win-back campaign
  2. Churn risk outreach
  3. Investigate friction points
  4. Offer migration/offboarding support
  
  Critical: Prevent churn in next 30 days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SEGMENT 5: New Adopters
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Size: 8,000 users (16%)

Profile:
  • Days Since Signup: 15 (-85% vs avg)
  • Monthly Sessions: 18 (+13% vs avg)
  • Total Revenue: $250 (-36% vs avg)
  • Feature Adoption: 45% (+3% vs avg)

Characteristics:
  ✓ Recent signups
  ✓ Good early engagement
  ✓ Still in trial/onboarding

Recommended Strategy:
  Priority: HIGH
  Focus: Activation & Conversion
  
  Actions:
  1. Optimize onboarding flow
  2. Trial-to-paid conversion campaigns
  3. Quick wins demonstration
  4. Early success check-ins
  
  Goal: Graduate to Power Users or Growth segments

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STRATEGIC PRIORITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Protect Power Users (17% of users, 45% of revenue)
   → Retention programs, VIP treatment

2. Engage Growth Potential (30% of users)
   → Feature education, +$3M revenue opportunity

3. Win Back At Risk (13% of users)
   → Prevent $2M annual churn

4. Convert New Adopters (16% of users)
   → Onboarding optimization

5. Decision on Free Riders (24% of users)
   → Monetize or optimize costs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Week 1:
  • Present segmentation to stakeholders
  • Validate segment definitions
  • Prioritize 2-3 segments for immediate action

Week 2-4:
  • Launch targeted campaigns for priority segments
  • Implement segment tracking in analytics
  • Create segment-specific dashboards

Ongoing:
  • Monitor segment migration (users moving between segments)
  • Refresh segmentation quarterly
  • Measure strategy effectiveness

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ user_segments.csv (user-level segments)
✓ segment_profiles.csv (aggregate profiles)
✓ segment_strategies.csv (recommended actions)
✓ segment_analysis.png (visualizations)
✓ optimal_clusters.png (cluster analysis)
```

## 일반적인 시나리오

### 시나리오 1: "우리의 최고 고객은 누구입니까?"
→ 클러스터링 분석 실행
→ 고가치 세그먼트 특성 식별
→ 인구통계 및 행동 프로파일링
→ 유사 타겟팅 전략 생성
→ 세그먼트 LTV 계산

### 시나리오 2: "제품 팀을 위한 페르소나 생성"
→ 클러스터링을 사용하여 자연적인 그룹 찾기
→ 정성적 연구로 강화
→ 세그먼트 이름을 기억하기 좋게 지정
→ 사용 사례 및 문제점 문서화
→ 제품 로드맵에 맵핑

### 시나리오 3: "이탈률이 높은 이유는? 어떤 사용자가 위험합니까?"
→ 참여도 + 수익으로 세분화
→ "위험" 세그먼트 식별
→ 공통 특성 분석
→ 개별 사용자의 이탈 위험 예측
→ 복원 캠페인 설계

### 시나리오 4: "기존 세분화 검증"
→ 비즈니스 정의 vs 데이터 기반 세그먼트 비교
→ 세그먼트 겹침/고유성 계산
→ 현재 세분화의 격차 표시
→ 개선 사항 제안
→ 시간 경과에 따른 세그먼트 성능 측정

### 시나리오 5: "고객 유형별 마케팅 개인화"
→ 실행 가능한 세그먼트 생성(너무 많지 않음)
→ 세그먼트별 메시징 선호도 프로파일링
→ 세그먼트별 지표 계산
→ 도구의 타겟팅 규칙 구축
→ 세그먼트별 캠페인 성능 추적

## 누락된 컨텍스트 처리

**사용자가 세분화를 원하지만 목적이 불분명:**
"세그먼트로 무엇을 할 것인지 이해해봅시다:
- 타겟팅된 마케팅 캠페인?
- 제품 우선순위?
- 가격 책정 전략?
- 고객 성공 포커스?

사용 사례가 올바른 세분화 접근법을 결정합니다."

**사용자가 제한된 행동 데이터 보유:**
"회사 규모, 산업, 요금제 유형별 회사 프로필/인구통계 세분화로 시작한 다음 행동 데이터가 사용 가능해지면서 강화할 수 있습니다."

**사용자가 "몇 개의 세그먼트?"라고 묻는 경우:**
"일반적인 범위는 3-7개 세그먼트입니다 - 실행 가능할 정도로 충분하지만 다르게 처리할 수 없을 정도로 많지는 않습니다. 최적의 수를 추천하기 위해 데이터를 분석하겠습니다."

**선택할 변수가 너무 많음:**
"다음과 같은 변수를 우선순위화합시다:
1. 사용자 간에 상당히 다양함
2. 비즈니스 성과(수익, 유지)와 관련
3. 실행 가능함(다르게 타겟팅할 수 있음)

가장 중요한 3-5개부터 시작하세요."

## 고급 옵션

기본 세분화 후 다음을 제안:

**RFM 분석**:
"전자상거래/구독 비즈니스의 경우 11가지 표준 카테고리를 사용하여 클래식 RFM(최근성, 빈도, 금전성) 세그먼트를 만들 수 있습니다."

**예측 세분화**:
"더 실행 가능한 타겟팅을 위해 세그먼트에 예측 점수(이탈 위험, 업셀 경향)를 추가할 수 있습니다."

**계층적 세분화**:
"중첩된 세그먼트를 원합니까? 예: 3개의 매크로 세그먼트로 각각을 2-3개의 마이크로 세그먼트로 분할하여 총 6-9개."

**세그먼트 마이그레이션 분석**:
"사용자가 시간 경과에 따라 세그먼트 간에 어떻게 이동하는지 추적하여 전략 효과를 측정할 수 있습니다."

**유사 모델링**:
"최고 세그먼트를 기반으로 새 사용자에게 초기 식별을 위해 유사성 점수를 매길 수 있습니다."

**동적 세분화**:
"사용자 행동이 변경될 때 자동화된 재세분화를 설정하고, 사용자가 세그먼트를 변경할 때 알림을 보낼 수 있습니다."
