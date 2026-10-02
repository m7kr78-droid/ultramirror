# UltraMirror — مرآة USB

نقل شاشة الآيفون للكمبيوتر عبر **كابل الشحن** بجودة عالية و60 إطار، بأقل تأخير عملي.

صفر تأخير غير ممكن: الالتقاط والترميز والعرض يحتاجون وقت. هذا المشروع يعطّل التخزين المؤقت ويستخدم USB بدل الواي فاي.

## وش تحتاج

- آيفون بـ iOS 15 أو أحدث
- ويندوز مع [Python 3.11+](https://www.python.org/downloads/)
- [Apple Devices](https://apps.microsoft.com/detail/9np83lwlpz9k) أو iTunes
- [Sideloadly](https://sideloadly.io) لتوقيع التطبيق
- ملف IPA (يُبنى على Mac أو من GitHub Actions، Sideloadly **ما يبني** السورس، هو يوقّع فقط)

## 1) برنامج الويندوز

1. ثبت Apple Devices أو iTunes.
2. اربط الآيفون، واضغط Trust.
3. من مجلد `windows/receiver` شغّل `run.bat`.
4. بعد ما يبدأ البث من الجوال، اضغط **بدء العرض**.

`Esc` تخرج من ملء الشاشة.

## 2) تطبيق الآيفون + Sideloadly

Sideloadly يوقّع IPA جاهز بحساب Apple ID. لازم أحد يبني الـ IPA مرة واحدة:

- على Mac: من مجلد `ios/UltraMirror` نفّذ `bash build-ipa.sh`
- أو ارفع المشروع لـ GitHub وشغّل Action اسمه **Build IPA**، بعدين حمّل الأرتفكت

بعدها:

1. افتح Sideloadly.
2. حط الـ IPA والآيفون وحساب Apple.
3. **لا تغيّر Bundle ID** حتى يظهر امتداد البث.
4. ثبّت، وعلى iOS 16+ فعّل Developer Mode.
5. افتح **مرآة USB**، اضغط الزر الأحمر، واختر نفس التطبيق.

## ملاحظات

- ReplayKit يطلع حتى 60FPS حتى لو شاشة الجوال 120Hz.
- إذا Sideloadly ما ظهر امتداد البث، أعد التثبيت بدون تغيير Bundle ID.
- إذا الويندوز ما شاف الجهاز: كابل أصلي، Trust، وخدمة Apple Mobile Device تعمل.
