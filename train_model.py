import pandas as pd
import pickle
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor

df = pd.read_csv("maize_yield_dataset_2000cleaned.csv")


target_column = "Yield_Bags_Per_Acre" 
X = df.drop(columns=[target_column]) 
y = df[target_column]  


X = pd.get_dummies(X)  

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)


with open("final_model.pkl", "wb") as file:
    pickle.dump(model, file)

print("✅ Model successfully trained and saved as 'final_model.pkl'")
