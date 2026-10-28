# Flosi (فلوسي): تطبيق أندرويد، طريقة البناء من التيليفون

ملاحظة: الكود ما تجربش ولا تبنا عندي (ما عنديش Flutter هنا). البناء كيتدار فـ GitHub، وإيلا وقع خطأ كتصيفطو لي ونصلحو.

## الملفات (13)
db.dart, state.dart, util.dart, widgets.dart, txn_sheet.dart, main.dart,
home_page.dart, history_page.dart, reports_page.dart, loans_page.dart,
more_page.dart, pubspec.yaml, icon.png, icon_fg.png  (+ build.yml)

## الخطوات
1. سير لـ github.com فـ Chrome وصاوب حساب مجاني.
2. New repository، سميتو `flosi`، خليه Private، Create.
3. فالـ repository: Add file ثم Upload files. اختار كل الملفات اللي سميتهم فوق (ماشي build.yml)، ثم Commit changes.
   إيلا ما خدمش الرفع، فعّل "Desktop site" فـ Chrome.
4. Add file ثم Create new file. فالسمية كتب بالضبط: `.github/workflows/build.yml`
   لصق داخلو محتوى الملف build.yml، ثم Commit changes.
5. تبويب Actions، ثم "Build Flosi APK"، ثم Run workflow. تسنى 5 حتى 10 دقايق.
6. ملي يوقع صح الأخضر: رجع للصفحة الرئيسية ديال الـ repository، من جنب "Releases" حل آخر واحد، ونزل `app-release.apk`.
7. حل الملف، وسمح بالتثبيت من هاد المصدر، ثم Install.

## إيلا ظهر X أحمر
حل الـ run، ضغط على الخطوة الحمرا، وكوبي آخر 30 سطر من الخطأ وسيفطهم ليا.

## نقل الأرقام من النسخة القديمة (الويب)
فالنسخة القديمة: صفحة "النسخة"، كوبي النص. فالتطبيق الجديد: المزيد، استرجاع من نسخة، لصق، أكد.
(كيدوز ديال الدخل، المصاريف، والسلف.)

## اختبار يدوي (بعد التثبيت)
- زيد خدمة (لاصال، 300)، ومصروف (النقل، 20): كيتبدل الباقي فالرئيسية.
- عدل التسجيل، ثم امسحو.
- سد التطبيق بزز (قتلو من التطبيقات) وحلو: الأرقام خاصها تبقى.
- زيد فئة وخدمة، وجرب البحث والفلتر فالسجل.
- التقارير: يومي وأسبوعي وشهري وسنوي.
- السلف: زيد، تخلص، رجّعو ما تخلصش.
- النسخة: كوبي، ثم استرجاع.

## المتطلبات (إيلا بغيتي تبني فكمبيوتر)
Flutter stable، ثم: flutter create --platforms android app، انسخ ملفات dart لـ app/lib، pubspec.yaml لـ app/،
icon*.png لـ app/assets/، ثم flutter pub get، dart run flutter_launcher_icons، flutter build apk --release
