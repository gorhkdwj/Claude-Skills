---
name: time-series-analysis
description: |
  시계열 데이터에서 시간대별 추세 패턴, 계절성, 이상값을 탐지하고 예측 모델을 구축하는 스킬.
  표 형식 데이터(CSV·JSON·Parquet·Excel 등)에서 날짜/시간 컬럼을 받아
  시계열 분해(Trend·Seasonal·Residual), 정상성 검정(ADF), ARIMA 예측 모델을 수행하며,
  신뢰도 구간이 포함된 미래 예측과 이상값 탐지 결과를 제공합니다.
  실행 결과가 내장된 Jupyter Notebook(time-series-analysis.ipynb),
  예측 결과 테이블(time-series-analysis_result.csv),
  한국어 해석 보고서(time-series-analysis_report.md)를 제공합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "내일, 다음 달 매출/사용자 수를 예측해줘" → 시계열 예측
  - "시간에 따라 어떤 패턴이 있어?" → 추세·계절성 분석
  - "이상한 데이터 포인트를 찾아줘", "비정상 거래 시점" → 이상값 탐지
  - "주간 반복/월간 반복 패턴이 있어?" → 계절성 검사
  - 날짜 인덱스가 있는 시계열 데이터를 시간대별로 분석할 때
---

# Time Series Analysis

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## Input
- 이전 스킬: programmatic-eda + data-quality-audit (필수) + semantic-model-builder + analysis-assumptions-log (선택)
- 받는 파일: 시계열 데이터 파일 + `context_packet.json` (analysis-path-guide / context-packager 생성)
- 선택: `programmatic-eda_result.csv`, `data-quality-audit_result.csv`

## Output
- `time-series-analysis.ipynb`
- `time-series-analysis_result.csv`
- `time-series-analysis_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## Quick Start

시계열 데이터에서 추세, 계절성, 이상값을 파악하고 신뢰도 구간이 포함된 예측을 생성하여 비즈니스 계획에 활용합니다.

## Context Requirements

시계열 분석 전에 다음이 필요합니다:

1. **시계열 데이터**: 시간에 따라 측정된 값들
2. **시간 단위**: 일, 주, 월, 시간 등 데이터 수집 주기
3. **예측 기간**: 얼마나 앞서서 예측할지(예: 30일 뒤)
4. **알려진 이벤트** (선택): 휴일, 캠페인, 데이터에 영향을 미친 특수 사건
5. **비즈니스 맥락**: 이 지표를 변화시키는 요인들

## Context Gathering

### 시계열 데이터:
"타임스탬프가 포함된 과거 데이터가 필요합니다:

**형식:**
```
date       | metric_value
2024-01-01 | 1,250
2024-01-02 | 1,320
2024-01-03 | 1,180
...
```

**요구사항:**
- 규칙적 간격 (간격 없음이 이상적)
- 최소 2개 이상의 계절 사이클
  - 일일 데이터: 2년 이상
  - 주간 데이터: 2년 이상
  - 월간 데이터: 3년 이상

**추가 변수** (선택이지만 유용):
- 외부 요인 (마케팅 지출, 날씨 등)
- 휴일 지시자
- 이벤트 플래그

어느 시간대의 데이터를 가지고 있습니까?"

### 시간 단위:
"데이터의 자연스러운 수집 단위는 무엇입니까?

**옵션:**
- **시간 단위**: 웹 트래픽, API 호출
- **일간**: 사용자 가입, 매출, 세션
- **주간**: 집계 비즈니스 지표
- **월간**: 재무 보고, 구독
- **분기**: 경영진급 지표

다음 기준으로 선택:
1. 데이터 수집 방식
2. 의사결정 빈도
3. 예측 사용 목적"

### 예측 기간:
"얼마나 앞서서 예측해야 합니까?

**일반적 기간:**
- **단기**: 1-7일 (운영 계획)
- **중기**: 1-3개월 (예산 사이클)
- **장기**: 6-12개월 (전략 계획)

주의: 기간이 길어질수록 예측 정확도가 감소합니다."

### 계절 패턴:
"이 지표에 알려진 패턴이 있습니까?

**일반적 패턴:**
- **요일**: 평일이 주말보다 높음
- **월간**: 월말 급증, 계절 추세
- **분기**: 소매업의 Q4 급증
- **연간**: 휴일 시즌, 회계연도 사이클
- **복합**: 주간 + 연간 (예: 여름 주말)

패턴 이해가 예측 정확도를 높입니다."

### 외부 요인:
"이 지표에 영향을 미치는 외부 요인은 무엇입니까?

**예시:**
- 마케팅 캠페인 (시작/종료 날짜)
- 제품 출시
- 가격 변동
- 경쟁사 조치
- 경제 지표
- 날씨 (일부 업종)
- 휴일

이들은 고급 예측 모델에 포함될 수 있습니다."

## 컨텍스트 패킷 자동 로드

시계열 분석을 시작하기 전에 `context_packet.json`을 읽어 핵심 설정을 자동으로 채웁니다.
패킷이 없으면 아래 Config Block의 변수를 수동으로 채워야 합니다.

```python
import json
import os
import pandas as pd

def load_ts_config_from_packet(packet_path="context_packet.json"):
    """
    context_packet.json에서 시계열 분석에 필요한 설정을 로드합니다.
    """
    config = {
        "DATA_PATH":        None,          # 데이터 파일 경로 (항상 수동 설정)
        "DATE_COL":         "date",        # 날짜 컬럼명 (기본값)
        "TARGET_COL":       "value",       # 분석 대상 수치 컬럼 (기본값)
        "TIME_INTERVAL":    None,          # 시간 간격 (일별/주별/월별)
        "FREQ":             None,          # pandas freq 문자열 (D/W/MS 등)
        "FORECAST_PERIODS": 30,            # 예측 기간 (기본 30)
        "DOMAIN_NOTES":     [],            # 도메인 노트 (특수 기간 등)
        "packet_loaded":    False
    }

    freq_map = {
        "일별": "D",   "시간별": "h",
        "주별": "W",   "월별":   "MS",
        "분기별": "QS", "연별":   "YS"
    }

    if not os.path.exists(packet_path):
        print("⚠️  context_packet.json 없음 — Config Block을 수동으로 설정하세요.")
        return config

    with open(packet_path, "r", encoding="utf-8") as f:
        packet = json.load(f)

    # 테이블 유형 유효성 검사
    table_type    = packet.get("table_type", "")
    time_col_role = packet.get("time_column_role", "없음")
    ts_valid = ("시계열" in str(table_type)) or (time_col_role in ["인덱스", "인덱스_후보"])

    if not ts_valid:
        print(f"⚠️  패킷의 table_type='{table_type}', time_column_role='{time_col_role}'")
        print(f"   시계열 분석에 적합하지 않을 수 있습니다. 데이터 유형을 확인해주세요.")

    # 설정 자동 채우기
    if packet.get("time_column_name"):
        config["DATE_COL"]      = packet["time_column_name"]

    if packet.get("target_col"):
        config["TARGET_COL"]    = packet["target_col"]

    interval = packet.get("time_interval", "없음")
    config["TIME_INTERVAL"]     = interval
    config["FREQ"]              = freq_map.get(interval)

    config["DOMAIN_NOTES"]      = packet.get("domain_notes", [])
    config["packet_loaded"]     = True

    return config

# ── Config Block ─────────────────────────────────────────────────────
# context_packet.json이 있으면 아래 값이 자동으로 채워집니다.
# DATA_PATH는 항상 직접 지정하세요.
ts_config = load_ts_config_from_packet()

DATA_PATH        = "시계열_데이터_파일_경로.csv"    # ← 항상 직접 지정
DATE_COL         = ts_config["DATE_COL"]            # 날짜 컬럼명
TARGET_COL       = ts_config["TARGET_COL"]          # 분석 대상 컬럼
FREQ             = ts_config["FREQ"]                # pandas freq (None이면 자동 탐지)
FORECAST_PERIODS = ts_config["FORECAST_PERIODS"]    # 예측 기간 (행 단위)

if ts_config["packet_loaded"]:
    print(f"📦 context_packet.json 로드 완료\n")
    print(f"  날짜 컬럼:    {DATE_COL}")
    print(f"  분석 대상:    {TARGET_COL}")
    print(f"  시간 간격:    {ts_config['TIME_INTERVAL']} → freq='{FREQ}'")
    print(f"  예측 기간:    {FORECAST_PERIODS}행")
    if ts_config["DOMAIN_NOTES"]:
        print(f"\n  📋 도메인 노트 (이상치·특수 기간 해석 시 참고):")
        for note in ts_config["DOMAIN_NOTES"]:
            print(f"     • {note}")
    print()
else:
    print("📋 수동 설정 필요:")
    print(f"  DATE_COL         = '{DATE_COL}'        ← 실제 날짜 컬럼명으로 수정")
    print(f"  TARGET_COL       = '{TARGET_COL}'      ← 분석할 수치 컬럼명으로 수정")
    print(f"  FREQ             = '{FREQ}'            ← 'D'(일)/W(주)/'MS'(월) 중 지정")
    print(f"  FORECAST_PERIODS = {FORECAST_PERIODS}  ← 예측 기간(행 수) 지정")
```

> **⚠️ FREQ가 None인 경우**: pandas가 자동 탐지하지만 불규칙 데이터에서 오류가 발생할 수 있습니다.
> 패킷의 `time_interval`이 `'불규칙'`이면 ARIMA 등 정기 주기 모델 적용 전에 리샘플링이 필요합니다.

---

## Workflow

### Step 1: Load and Visualize Time Series

```python
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import adfuller, acf, pacf
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.arima.model import ARIMA
from sklearn.metrics import mean_absolute_error, mean_squared_error
import warnings
warnings.filterwarnings('ignore')

# ── 데이터 로드 (Config Block 값 사용) ───────────────────────────────
def load_file(path):
    ext = path.split('.')[-1].lower()
    try:
        if ext == 'csv':
            try:    return pd.read_csv(path, encoding='utf-8')
            except: return pd.read_csv(path, encoding='cp949')
        elif ext == 'tsv':
            try:    return pd.read_csv(path, sep='\t', encoding='utf-8')
            except: return pd.read_csv(path, sep='\t', encoding='cp949')
        elif ext in ['xlsx', 'xls']: return pd.read_excel(path)
        elif ext == 'json':          return pd.read_json(path)
        elif ext == 'parquet':       return pd.read_parquet(path)
    except Exception as e:
        raise RuntimeError(f"파일 로드 실패: {e}")

df = load_file(DATA_PATH)
df[DATE_COL] = pd.to_datetime(df[DATE_COL])
df = df.sort_values(DATE_COL)
df.set_index(DATE_COL, inplace=True)

# FREQ가 지정된 경우 인덱스에 적용 (누락 날짜 경고 제거)
if FREQ:
    df = df.asfreq(FREQ)
    if df[TARGET_COL].isnull().sum() > 0:
        print(f"⚠️  freq='{FREQ}' 적용 후 {df[TARGET_COL].isnull().sum()}개 결측 발생 — 보간 권장")

print(f"📊 시계열 데이터 로드 완료:")
print(f"  시작: {df.index.min()}")
print(f"  종료: {df.index.max()}")
print(f"  관측 수: {len(df):,}")
print(f"  freq: {df.index.inferred_freq or FREQ or 'Unknown'}")
print(f"  대상 컬럼: {TARGET_COL}  (결측: {df[TARGET_COL].isnull().sum()}개)")

# ── 원시 시계열 시각화 ────────────────────────────────────────────
plt.figure(figsize=(14, 6))
plt.plot(df.index, df[TARGET_COL], linewidth=1.5)
plt.title(f'시계열 플롯 — {TARGET_COL}')
plt.xlabel(DATE_COL)
plt.ylabel(TARGET_COL)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('time_series_plot.png', dpi=300, bbox_inches='tight')
plt.show()
```

**확인**: "데이터 로딩 완료. 시간 범위가 적절합니까? 명백한 문제가 없습니까?"

### Step 2: Check for Stationarity

```python
def test_stationarity(timeseries):
    """
    확대 디키-풀러(Augmented Dickey-Fuller) 검정을 사용하여 시계열이 정상(stationary)인지 확인
    """

    # Perform ADF test
    result = adfuller(timeseries.dropna())

    print('\n📈 정상성 검정 (확대 디키-풀러):')
    print(f'  ADF 통계량: {result[0]:.4f}')
    print(f'  P-value: {result[1]:.4f}')
    print(f'  임계값:')
    for key, value in result[4].items():
        print(f'    {key}: {value:.3f}')

    if result[1] <= 0.05:
        print(f'  ✅ 정상 시계열: 귀무가설 기각 (p < 0.05)')
        print(f'     시계열에 단위근 없음')
        stationary = True
    else:
        print(f'  ⚠️  비정상 시계열: 귀무가설 기각 불가 (p > 0.05)')
        print(f'     시계열에 추세/계절성 있을 수 있음')
        print(f'     1차 차분(differencing) 또는 추세 제거 고려')
        stationary = False

    return stationary

is_stationary = test_stationarity(df[TARGET_COL])
```

### Step 3: Decompose Time Series

```python
def decompose_time_series(df, period=None):
    """
    시계열을 추세, 계절성, 잔차 성분으로 분해
    """

    # 지정되지 않으면 주기 자동 결정
    if period is None:
        freq = df.index.inferred_freq
        if freq and 'D' in freq:
            period = 7  # 일일 데이터의 주간 계절성
        elif freq and ('W' in freq or 'M' in freq):
            period = 12  # 주간/월간 데이터의 연간 계절성
        else:
            period = 12  # 기본값

    # 분해 수행
    decomposition = seasonal_decompose(df[TARGET_COL], model='additive', period=period)

    # 성분 플롯
    fig, axes = plt.subplots(4, 1, figsize=(14, 10))

    # 원본
    df[TARGET_COL].plot(ax=axes[0], title=f'원본 시계열 — {TARGET_COL}')
    axes[0].set_ylabel(TARGET_COL)

    # 추세
    decomposition.trend.plot(ax=axes[1], title='Trend Component')
    axes[1].set_ylabel('Trend')

    # 계절성
    decomposition.seasonal.plot(ax=axes[2], title='Seasonal Component')
    axes[2].set_ylabel('Seasonal')

    # 잔차
    decomposition.resid.plot(ax=axes[3], title='Residual Component')
    axes[3].set_ylabel('Residual')

    plt.tight_layout()
    plt.savefig('decomposition.png', dpi=300, bbox_inches='tight')
    plt.show()

    # 성분 강도 계산
    trend_strength = 1 - (decomposition.resid.var() /
                         (decomposition.trend + decomposition.resid).var())
    seasonal_strength = 1 - (decomposition.resid.var() /
                             (decomposition.seasonal + decomposition.resid).var())

    print(f"\n📊 분해 분석:")
    print(f"  추세 강도: {trend_strength:.1%}")
    print(f"  계절성 강도: {seasonal_strength:.1%}")

    if trend_strength > 0.6:
        print(f"  ↗️  강한 추세 감지")
    if seasonal_strength > 0.6:
        print(f"  🔄 강한 계절성 감지")

    return decomposition

decomposition = decompose_time_series(df)
```

### Step 4: Detect Anomalies

```python
def detect_anomalies(df, method='iqr', window=30):
    """
    여러 방법을 사용하여 시계열에서 이상값 탐지
    """
    
    anomalies = pd.DataFrame(index=df.index)
    anomalies['value'] = df[TARGET_COL]
    
    # Method 1: IQR-based detection
    if method in ['iqr', 'all']:
        rolling_median = df[TARGET_COL].rolling(window=window, center=True).median()
        rolling_std = df[TARGET_COL].rolling(window=window, center=True).std()

        # Calculate z-score equivalent
        z_score = np.abs((df[TARGET_COL] - rolling_median) / rolling_std)
        anomalies['iqr_anomaly'] = z_score > 3
    
    # Method 2: Statistical outliers (MAD - Median Absolute Deviation)
    if method in ['mad', 'all']:
        median = df[TARGET_COL].median()
        mad = np.median(np.abs(df[TARGET_COL] - median))
        modified_z_score = 0.6745 * (df[TARGET_COL] - median) / mad
        anomalies['mad_anomaly'] = np.abs(modified_z_score) > 3.5
    
    # Method 3: Residual-based (using decomposition)
    if method in ['residual', 'all']:
        try:
            decomp = seasonal_decompose(df[TARGET_COL], model='additive', period=7)
            resid_std = decomp.resid.std()
            anomalies['residual_anomaly'] = np.abs(decomp.resid) > 3 * resid_std
        except:
            anomalies['residual_anomaly'] = False
    
    # Combine methods (any method flags as anomaly)
    if method == 'all':
        anomalies['is_anomaly'] = (
            anomalies['iqr_anomaly'] | 
            anomalies['mad_anomaly'] | 
            anomalies['residual_anomaly']
        )
    else:
        anomalies['is_anomaly'] = anomalies[f'{method}_anomaly']
    
    # Plot anomalies
    plt.figure(figsize=(14, 6))
    plt.plot(df.index, df[TARGET_COL], label='정상', alpha=0.7)

    if anomalies['is_anomaly'].any():
        anomaly_points = anomalies[anomalies['is_anomaly']]
        plt.scatter(anomaly_points.index, anomaly_points['value'],
                   color='red', s=100, label='이상값', zorder=5)

    plt.title(f'이상값 탐지 — {TARGET_COL}')
    plt.xlabel(DATE_COL)
    plt.ylabel(TARGET_COL)
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig('anomalies.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # 이상값 보고
    anomaly_dates = anomalies[anomalies['is_anomaly']].index
    print(f"\n🚨 탐지된 이상값: {len(anomaly_dates)}개")

    if len(anomaly_dates) > 0:
        print(f"\n  상위 5개 극단 이상값:")
        top_anomalies = anomalies[anomalies['is_anomaly']].nlargest(5, 'value')
        for date, row in top_anomalies.iterrows():
            print(f"    {date.strftime('%Y-%m-%d')}: {row['value']:,.0f}")

    return anomalies

anomalies = detect_anomalies(df, method='all')
```

### Step 5: Build Forecast Model

```python
def build_forecast_model(df, forecast_periods=30):
    """
    ARIMA 예측 모델 구축
    """

    # 학습/검증으로 분리
    train_size = int(len(df) * 0.8)
    train, test = df[:train_size], df[train_size:]

    print(f"\n🔮 예측 모델 구축:")
    print(f"  학습셋 크기: {len(train)}개")
    print(f"  검증셋 크기: {len(test)}개")
    print(f"  예측 기간: {forecast_periods}개")
    
    # Auto ARIMA (간단한 버전 - 더 좋은 결과는 pmdarima.auto_arima 사용)
    # 기본값으로 간단한 ARIMA(1,1,1) 사용
    model = ARIMA(train[TARGET_COL], order=(1, 1, 1))
    model_fit = model.fit()

    print(f"\n  모델: ARIMA(1,1,1)")
    print(f"  AIC: {model_fit.aic:.2f}")

    # 검증셋에서 예측
    forecast_test = model_fit.forecast(steps=len(test))

    # 오차 계산
    mae = mean_absolute_error(test['value'], forecast_test)
    rmse = np.sqrt(mean_squared_error(test['value'], forecast_test))
    mape = np.mean(np.abs((test['value'] - forecast_test) / test['value'])) * 100

    print(f"\n  📊 검증셋 성능:")
    print(f"    평균절대오차(MAE): {mae:.2f}")
    print(f"    제곱근평균제곱오차(RMSE): {rmse:.2f}")
    print(f"    평균절대백분율오차(MAPE): {mape:.1f}%")
    
    # 전체 데이터로 재학습
    model_full = ARIMA(df['value'], order=(1,1,1))
    model_full_fit = model_full.fit()

    # 미래 예측 생성
    forecast_result = model_full_fit.get_forecast(steps=forecast_periods)
    forecast_mean = forecast_result.predicted_mean
    forecast_ci = forecast_result.conf_int()

    # 예측 날짜 생성
    last_date = df.index[-1]
    freq = df.index.inferred_freq or 'D'
    forecast_dates = pd.date_range(start=last_date + pd.Timedelta(days=1),
                                   periods=forecast_periods, freq=freq)

    forecast_df = pd.DataFrame({
        'forecast': forecast_mean.values,
        'lower_ci': forecast_ci.iloc[:, 0].values,
        'upper_ci': forecast_ci.iloc[:, 1].values
    }, index=forecast_dates)

    return model_full_fit, forecast_df, mae, rmse, mape

model, forecast, mae, rmse, mape = build_forecast_model(df, forecast_periods=FORECAST_PERIODS)
```

### Step 6: Visualize Forecast

```python
def plot_forecast(df, forecast, title='Time Series Forecast'):
    """
    신뢰도 구간과 함께 과거 데이터 및 예측 시각화
    """

    fig, ax = plt.subplots(figsize=(14, 6))

    # 과거 데이터 플롯
    ax.plot(df.index, df['value'], label='Historical', linewidth=2)

    # 예측 플롯
    ax.plot(forecast.index, forecast['forecast'],
           label='Forecast', linewidth=2, linestyle='--', color='red')

    # 신뢰도 구간 플롯
    ax.fill_between(forecast.index,
                    forecast['lower_ci'],
                    forecast['upper_ci'],
                    alpha=0.2, color='red', label='95% 신뢰도 구간')

    # 예측 시작점에 수직선 추가
    ax.axvline(df.index[-1], color='black', linestyle=':', alpha=0.5)

    ax.set_xlabel('Date')
    ax.set_ylabel('Value')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig('forecast.png', dpi=300, bbox_inches='tight')
    plt.show()

    # 예측 요약 출력
    print(f"\n📅 예측 요약:")
    print(f"\n  다음 7일:")
    print(forecast.head(7).to_string())

plot_forecast(df, forecast)
```

### Step 7: Analyze Forecast Uncertainty

```python
def analyze_uncertainty(forecast):
    """
    예측 불확실성 정량화
    """

    forecast['uncertainty_pct'] = (
        (forecast['upper_ci'] - forecast['lower_ci']) / forecast['forecast'] * 100
    )

    print(f"\n📊 예측 불확실성 분석:")
    print(f"  평균 불확실성: {forecast['uncertainty_pct'].mean():.1f}%")
    print(f"  단기 (1-7일): {forecast['uncertainty_pct'][:7].mean():.1f}%")
    print(f"  중기 (8-14일): {forecast['uncertainty_pct'][7:14].mean():.1f}%")
    print(f"  장기 (15일 이후): {forecast['uncertainty_pct'][14:].mean():.1f}%")

    if forecast['uncertainty_pct'].mean() < 10:
        confidence = "높음"
    elif forecast['uncertainty_pct'].mean() < 20:
        confidence = "중간"
    else:
        confidence = "낮음"

    print(f"\n  예측 신뢰도: {confidence}")

    return confidence

confidence = analyze_uncertainty(forecast)
```

### Step 8: Generate Insights and Recommendations

```python
def generate_insights(df, decomposition, anomalies, forecast, confidence):
    """
    발견사항을 실행 가능한 인사이트로 통합
    """

    print(f"\n{'='*70}")
    print("💡 주요 인사이트")
    print('='*70)

    # 추세 인사이트
    recent_trend = decomposition.trend.dropna().iloc[-30:].mean()
    older_trend = decomposition.trend.dropna().iloc[-60:-30].mean()
    trend_change = (recent_trend - older_trend) / older_trend * 100

    print(f"\n📈 추세:")
    if abs(trend_change) < 5:
        print(f"  상태: 안정적")
        print(f"  최근 vs 이전: {trend_change:+.1f}%")
    elif trend_change > 5:
        print(f"  상태: ↗️  성장 중")
        print(f"  최근 vs 이전: {trend_change:+.1f}%")
        print(f"  조치: 성장 모멘텀 활용")
    else:
        print(f"  상태: ↘️  감소 중")
        print(f"  최근 vs 이전: {trend_change:+.1f}%")
        print(f"  조치: 감소 원인 조사")

    # 계절성 인사이트
    seasonal_range = decomposition.seasonal.max() - decomposition.seasonal.min()
    seasonal_pct = seasonal_range / df['value'].mean() * 100

    print(f"\n🔄 계절성:")
    print(f"  계절 변동: 평균의 {seasonal_pct:.1f}%")
    if seasonal_pct > 20:
        print(f"  상태: 강한 계절 패턴")
        print(f"  조치: 계절 피크에 대한 재고/인원 계획")
    elif seasonal_pct > 10:
        print(f"  상태: 중간 계절 패턴")
        print(f"  조치: 계절 조정 고려")
    else:
        print(f"  상태: 최소한의 계절성")

    # 이상값 인사이트
    anomaly_count = anomalies['is_anomaly'].sum()
    anomaly_pct = anomaly_count / len(anomalies) * 100

    print(f"\n🚨 이상값:")
    print(f"  총 탐지: {anomaly_count}개 ({anomaly_pct:.1f}%)")
    if anomaly_pct > 5:
        print(f"  상태: 높은 이상값 발생률")
        print(f"  조치: 데이터 품질 또는 비정상 이벤트 조사")
    else:
        print(f"  상태: 정상 이상값 발생률")

    # 예측 인사이트
    forecast_direction = "상승" if forecast['forecast'].iloc[7] > df['value'].iloc[-1] else "하강"
    forecast_change = abs(forecast['forecast'].iloc[7] - df['value'].iloc[-1]) / df['value'].iloc[-1] * 100

    print(f"\n🔮 예측 (다음 7일):")
    print(f"  방향: {forecast_direction}")
    print(f"  예상 변화: {forecast_change:.1f}%")
    print(f"  예측 신뢰도: {confidence}")

    if confidence == "높음":
        print(f"  조치: 자신 있게 계획에 예측 사용")
    elif confidence == "중간":
        print(f"  조치: 예측 사용하되 버퍼 포함")
    else:
        print(f"  조치: 방향 지표로만 예측 사용")

generate_insights(df, decomposition, anomalies, forecast, confidence)

# Save results
forecast.to_csv('forecast_results.csv')
anomalies.to_csv('detected_anomalies.csv')
```

## Context Validation

진행하기 전에 다음을 확인하세요:
- [ ] 충분한 과거 데이터 있음 (2개 이상 계절 사이클)
- [ ] 시계열 규칙적 간격 (최소한의 간격)
- [ ] 계절 패턴과 외부 요인 이해
- [ ] 예측 기간이 비즈니스 계획 필요와 일치
- [ ] 예측 사용 방식 알고 있음 (의사결정 맥락)

## Output Template

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
시계열 분석 보고서
지표: 일일 활성 사용자(DAU)
기간: 2023년 1월 - 2024년 12월 (730일)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 과거 분석
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

시계열 특성:
  ✅ 정상성: 있음 (ADF p-value: 0.012)
  📈 추세 강도: 75% (강한 상승 추세)
  🔄 계절성 강도: 62% (명확한 주간 패턴)
  📉 노이즈 수준: 15%

분해 요약:
  • 추세: 기간 동안 +25% 성장
  • 계절성: 최고점과 최저점 간 30% 변동
  • 패턴: 평일에 높음, 주말에 감소

탐지된 이상값: 15개 (일일 2.1%)
  상위 이상값:
    • 2024-07-04: 45,000명 (휴일 급증)
    • 2024-11-28: 52,000명 (블랙프라이데이)
    • 2024-03-15: 18,000명 (시스템 장애)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔮 예측 (향후 30일)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

모델: ARIMA(1,1,1)
  AIC: 8,234.5
  테스트 MAPE: 5.2% (좋은 정확도)

예측 신뢰도: 높음

향후 7일 예측:
  1일: 32,500명 [31,800 - 33,200]
  2일: 33,100명 [32,300 - 33,900]
  3일: 33,800명 [32,900 - 34,700]
  4일: 34,200명 [33,200 - 35,200]
  5일: 34,500명 [33,400 - 35,600]
  6일: 30,800명 [29,700 - 31,900] (주말 감소)
  7일: 29,500명 [28,300 - 30,700] (주말 감소)

한 달 예측:
  평균: 일일 32,750명
  범위: [31,200 - 34,300]
  불확실성: ±10%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 주요 인사이트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 강한 성장 추세
   • 2년 동안 25% 증가
   • 최근 몇 개월 가속화 중
   • 모멘텀: 긍정적

2. 예측 가능한 주간 패턴
   • 평일이 주말보다 30% 높음
   • 안정적 패턴으로 정확한 예측 가능
   • 기회: 주말 참여 증진

3. 휴일 영향 상당함
   • 주요 휴일에 +50% 급증
   • 향후 휴일에 대한 용량 계획 필요
   • 2024년 블랙프라이데이: 52,000명 (최고 기록)

4. 계절성 추세
   • Q4가 가장 강한 분기 (휴일 쇼핑)
   • 여름 개월에 약간의 감소
   • 계절 패턴에 따라 마케팅 계획

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 권장사항
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

긴급 조치:
  1. 다음 달 용량 계획에 예측 사용
  2. 일일 32-35,000명 범위 준비
  3. 주말 감소에 대해 15% 버퍼 포함

전략적 조치:
  4. 주말 참여 기회 조사
  5. 휴일 피크 준비 (2025년 Q4)
  6. 감소 신호에 대한 추세 모니터링

모니터링:
  7. 자동화된 이상값 경보 설정
  8. 매주 예측 갱신
  9. 실제 vs 예측 정확도 추적

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 생성된 파일
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ time_series_plot.png (과거 데이터)
✓ decomposition.png (추세/계절성 성분)
✓ anomalies.png (이상값 탐지)
✓ forecast.png (30일 예측 및 신뢰도 구간)
✓ forecast_results.csv (상세 예측)
✓ detected_anomalies.csv (이상값 목록)
```

## Common Scenarios

### 시나리오 1: "다음 분기 매출 예측"
→ ARIMA 또는 Prophet 모델 구축
→ 계절성과 추세 포함
→ 포인트 예측 + 신뢰도 구간 생성
→ 과거 정확도에 대해 검증
→ 비즈니스 계획 범위 제공

### 시나리오 2: "웹 트래픽의 이상값 탐지"
→ 과거 패턴을 사용한 기준선 설정
→ 통계적 이상치 플래그
→ 이상값 원인 조사
→ 자동화된 모니터링 설정
→ 경보 임계값 생성

### 시나리오 3: "지표 변화의 원인 파악"
→ 추세/계절성/잔차로 분해
→ 각 성분의 강도 정량화
→ 외부 이벤트와 상관관계 분석
→ 주요 드라이버 파악
→ 실행 가능한 인사이트 제공

### 시나리오 4: "인프라 용량 계획"
→ 피크 사용 기간 예측
→ 불확실성에 대한 버퍼 추가
→ 알려진 향후 이벤트 포함
→ 필요 자원 계산
→ 실제 vs 예측 모니터링

### 시나리오 5: "전년 동기 성장 추세 비교"
→ 계절성에 대해 정규화
→ 연간 변화율 계산
→ 통계적 유의성 검정
→ 변곡점 파악
→ 향후 궤적 예측

## Handling Missing Context

**사용자가 불규칙한 시계열 보유:**
"데이터에 간격이 있습니다. 옵션:
1. 결측값 대체 (선형 보간, 보전 기법)
2. 불규칙 시계열 모델링 (다른 접근)
3. 더 낮은 시간 단위로 집계 (일간 → 주간)

어느 것이 사용 사례에 가장 적합합니까?"

**사용자가 예측 기간을 모를 때:**
"질문: 이 예측이 어떤 의사결정에 영향을 미칠 것입니까?
- 운영 계획: 1-2주
- 예산 사이클: 1-3개월
- 전략 계획: 6-12개월

일반적 범위: 30-90일 앞"

**제한된 과거 데이터:**
"{X}개 관측치만으로는 예측 불확실성이 높을 것입니다. 다음 중 가능합니까:
- 아카이브/로그에서 더 많은 과거 데이터 제공?
- 비즈니스 가정으로 보완?
- 간단한 이동평균 접근부터 시작?"

**여러 계절 패턴:**
"일일, 주간, 연간 패턴이 모두 보입니다. 다음 중 선택:
1. 각각 별도로 모델링
2. 더 정교한 모델 사용 (Prophet, TBATS)
3. 가장 중요한 패턴에 집중

사용 사례에서 어느 것이 가장 중요합니까?"

## Advanced Options

기본 분석 이후, 다음 제공:

**Prophet 모델**:
"복잡한 계절성 + 휴일이 있으면 Facebook Prophet을 사용하여 더 견고한 예측을 생성할 수 있습니다."

**다변량 예측**:
"외부 변수(마케팅 지출, 날씨)가 있으면 이를 포함하여 더 나은 예측을 할 수 있습니다."

**앙상블 예측**:
"여러 모델(ARIMA, Prophet 등)을 결합하여 더 신뢰할 수 있는 예측을 생성할 수 있습니다."

**개입 분석**:
"특정 이벤트(제품 출시, 장애)의 시계열에 대한 영향을 정량화할 수 있습니다."

**자동 모니터링**:
"일일/주간 실행되는 자동화된 예측 갱신 및 이상값 경보를 설정할 수 있습니다."

**신뢰도 구간 보정**:
"과거 예측을 사용하여 신뢰도 구간이 적절히 보정되었는지 검증할 수 있습니다."
