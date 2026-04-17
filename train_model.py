"""
VAANI SEVA — Optimized ML Training Pipeline
============================================
Run: python train_model.py
Outputs: model.pkl, explainer.pkl, features.json, best_params.json
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import shap
import pickle
import json
import warnings
warnings.filterwarnings('ignore')

from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.metrics import (classification_report, accuracy_score,
                              roc_auc_score, f1_score, confusion_matrix)
from imblearn.over_sampling import SMOTE
import optuna
optuna.logging.set_verbosity(optuna.logging.WARNING)

# ── CONFIG ──────────────────────────────────────────────────
DATA_PATH   = 'vaani_seva_training.csv'
N_TRIALS    = 60     # Optuna search trials — increase for better params
N_CV_FOLDS  = 5      # Cross-validation folds
TEST_SIZE   = 0.2
RANDOM_SEED = 42

# ── 1. LOAD & FIX ELIGIBILITY LOGIC ─────────────────────────
def correct_eligibility(row):
    """
    Fixed logic: govt_emp / taxpayer check happens BEFORE age override.
    Original data_gen.py had a bug where age>=70 bypassed these disqualifiers.
    """
    if row['is_govt_emp'] == 1:  return 0   # Disqualified
    if row['is_taxpayer'] == 1:  return 0   # Disqualified
    if row['age'] >= 70:         return 1   # Ayushman Bharat Senior
    if row['is_rural'] == 1 and row['land_size'] <= 5 and row['income'] <= 300000:
        return 1  # PM-Kisan / rural smallholder
    if row['is_rural'] == 1 and row['house_type'] == 0 and row['income'] <= 180000:
        return 1  # PMAY-G (no pucca house)
    return 0

def load_and_prepare(path):
    df = pd.read_csv(path)
    df['eligible'] = df.apply(correct_eligibility, axis=1)
    print(f"✅ Loaded {len(df)} samples | Eligible: {df['eligible'].mean()*100:.1f}%")
    return df

# ── 2. FEATURE ENGINEERING ──────────────────────────────────
def engineer_features(df):
    """
    9 derived features on top of the 7 original ones.
    These give XGBoost pre-computed domain signals to exploit.
    """
    df = df.copy()

    # Continuous interactions
    df['income_per_acre']   = df['income'] / (df['land_size'] + 1e-5)

    # Age buckets (scheme thresholds are age-gated)
    df['is_senior']         = (df['age'] >= 60).astype(int)
    df['is_very_senior']    = (df['age'] >= 70).astype(int)
    df['is_young_adult']    = ((df['age'] >= 18) & (df['age'] <= 35)).astype(int)

    # Compound welfare indicators
    df['low_income_rural']  = ((df['is_rural'] == 1) & (df['income'] <= 300000)).astype(int)
    df['poor_rural_farmer'] = ((df['is_rural'] == 1) & (df['land_size'] <= 5)
                                & (df['income'] <= 300000)).astype(int)

    # Ordinal bands (captures non-linear income/land effects)
    df['income_band'] = pd.cut(
        df['income'],
        bins=[0, 100000, 200000, 300000, 500000, 800001],
        labels=[0, 1, 2, 3, 4]
    ).astype(int)
    df['land_band'] = pd.cut(
        df['land_size'],
        bins=[-0.1, 1, 2, 5, 10, 15.1],
        labels=[0, 1, 2, 3, 4]
    ).astype(int)

    # Single risk signal: negative for disqualifiers, positive for qualifiers
    df['risk_score'] = (df['is_rural'] + df['low_income_rural']
                        - df['is_taxpayer'] - df['is_govt_emp'])

    return df

FEATURES = [
    # Original 7
    'age', 'income', 'land_size', 'is_rural', 'house_type',
    'is_taxpayer', 'is_govt_emp',
    # Engineered 9
    'income_per_acre', 'is_senior', 'is_very_senior', 'is_young_adult',
    'low_income_rural', 'poor_rural_farmer', 'income_band', 'land_band', 'risk_score'
]

# ── 3. OPTUNA HYPERPARAMETER SEARCH ─────────────────────────
def build_objective(X_train, y_train):
    def objective(trial):
        params = {
            'n_estimators':     trial.suggest_int('n_estimators', 100, 500),
            'max_depth':        trial.suggest_int('max_depth', 3, 8),
            'learning_rate':    trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'subsample':        trial.suggest_float('subsample', 0.6, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
            'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
            'gamma':            trial.suggest_float('gamma', 0.0, 0.5),
            'reg_alpha':        trial.suggest_float('reg_alpha', 0.0, 1.0),
            'reg_lambda':       trial.suggest_float('reg_lambda', 0.5, 2.0),
            'scale_pos_weight': trial.suggest_float('scale_pos_weight', 0.5, 2.0),
            'use_label_encoder': False,
            'eval_metric': 'auc',
            'random_state': RANDOM_SEED,
            'n_jobs': -1,
        }
        model = xgb.XGBClassifier(**params)
        cv = StratifiedKFold(n_splits=N_CV_FOLDS, shuffle=True, random_state=RANDOM_SEED)
        return cross_val_score(
            model, X_train, y_train, cv=cv, scoring='roc_auc', n_jobs=-1
        ).mean()
    return objective

# ── 4. EVALUATION REPORT ─────────────────────────────────────
def print_evaluation(model, X_test, y_test):
    y_pred      = model.predict(X_test)
    y_pred_prob = model.predict_proba(X_test)[:, 1]
    cm          = confusion_matrix(y_test, y_pred)

    print("\n" + "=" * 60)
    print("📊 MODEL PERFORMANCE")
    print("=" * 60)
    print(f"  Accuracy  : {accuracy_score(y_test, y_pred)*100:.2f}%")
    print(f"  ROC-AUC   : {roc_auc_score(y_test, y_pred_prob):.4f}")
    print(f"  F1 Score  : {f1_score(y_test, y_pred):.4f}")
    print(f"\n  Confusion Matrix:")
    print(f"  TN={cm[0][0]}  FP={cm[0][1]}")
    print(f"  FN={cm[1][0]}  TP={cm[1][1]}")
    print(f"\n{classification_report(y_test, y_pred, target_names=['Not Eligible','Eligible'])}")

    # Feature importances
    feat_imp = pd.Series(model.feature_importances_, index=FEATURES).sort_values(ascending=False)
    print("🏆 Top 10 Feature Importances:")
    for feat, score in feat_imp.head(10).items():
        bar = "█" * int(score * 100)
        print(f"  {feat:<22} {score:.4f} {bar}")

# ── 5. SHAP EXPLANATION DEMO ─────────────────────────────────
def demo_shap(explainer, X_test):
    """
    This is what judges will see — WHY a user qualifies, not just that they do.
    """
    shap_vals = explainer.shap_values(X_test.iloc[:3])
    print("\n🔬 SHAP Explanation — User 1:")
    user_shap = pd.Series(shap_vals[0], index=FEATURES).sort_values(key=abs, ascending=False)
    for feat, val in user_shap.head(5).items():
        direction = "✅ helps qualify" if val > 0 else "❌ hurts eligibility"
        print(f"  {feat:<22} {val:+.4f}  {direction}")

# ── MAIN ─────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("VAANI SEVA — OPTIMIZED MODEL TRAINING PIPELINE")
    print("=" * 60)

    # Load + fix + engineer
    df = load_and_prepare(DATA_PATH)
    df = engineer_features(df)
    print(f"   Feature count: {len(FEATURES)} (7 original + 9 engineered)")

    X, y = df[FEATURES], df['eligible']

    # Stratified split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_SIZE, random_state=RANDOM_SEED, stratify=y
    )

    # SMOTE — balance training set only (never touch test set)
    smote = SMOTE(random_state=RANDOM_SEED)
    X_train_bal, y_train_bal = smote.fit_resample(X_train, y_train)
    print(f"   After SMOTE: {dict(pd.Series(y_train_bal).value_counts())}")

    # Optuna search
    print(f"\n🔍 Searching hyperparameters ({N_TRIALS} trials)...")
    study = optuna.create_study(direction='maximize')
    study.optimize(build_objective(X_train_bal, y_train_bal),
                   n_trials=N_TRIALS, show_progress_bar=True)
    best_params = study.best_params
    best_params.update({
        'use_label_encoder': False,
        'eval_metric': 'auc',
        'random_state': RANDOM_SEED,
        'n_jobs': -1
    })
    print(f"   Best CV AUC: {study.best_value:.4f}")

    # Final model
    print("\n🚀 Training final model on balanced data...")
    model = xgb.XGBClassifier(**best_params)
    model.fit(X_train_bal, y_train_bal,
              eval_set=[(X_test, y_test)], verbose=False)

    # Evaluate
    print_evaluation(model, X_test, y_test)

    # SHAP
    print("\n🔬 Building SHAP explainer...")
    explainer = shap.TreeExplainer(model)
    demo_shap(explainer, X_test)

    # Save all artifacts
    with open('model.pkl',     'wb') as f: pickle.dump(model, f)
    with open('explainer.pkl', 'wb') as f: pickle.dump(explainer, f)
    with open('features.json', 'w')  as f: json.dump(FEATURES, f)
    with open('best_params.json', 'w') as f:
        json.dump({k: (round(v, 6) if isinstance(v, float) else v)
                   for k, v in best_params.items()}, f, indent=2)

    print("\n✅ Saved: model.pkl | explainer.pkl | features.json | best_params.json")
    print("\n" + "=" * 60)
    print("🎯 DONE — next step: python app.py")
    print("=" * 60)

if __name__ == "__main__":
    main()