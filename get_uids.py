import re

with open("TranslatorBar.xcodeproj/project.pbxproj") as f:
    content = f.read()

app = re.search(r'(\w{24}) = \{[^}]*name = TranslatorBar;[^}]*productType = "com\.apple\.product-type\.application"', content, re.DOTALL)
test = re.search(r'(\w{24}) = \{[^}]*name = TranslatorBarTests;[^}]*productType = "com\.apple\.product-type\.bundle\.unit-test"', content, re.DOTALL)
app_prod = re.search(r'(\w{24}) = \{[^}]*explicitFileType = wrapper\.application[^}]*path = TranslatorBar\.app', content, re.DOTALL)

print("APP_TARGET:", app.group(1) if app else "NOT FOUND")
print("TEST_TARGET:", test.group(1) if test else "NOT FOUND")
print("APP_PRODUCT:", app_prod.group(1) if app_prod else "NOT FOUND")
