This Flutter App serves as a Passive thermal-print service for any other App that need to use thermal printing capabilities.
Passive means you dont need to run it, it can be fired throughout android Intents.

## Getting Started

the project uses the following dependencies, thus dont forget to add it if you decide to clone this project

-Permission -dependency
flutter pub add permission_handler

-Bluetooth pakage - dependency
flutter pub add print_bluetooth_thermal

-Thermal pakage - dependency
flutter pub add esc_pos_utils
flutter pub add esc_pos_utils_plus

-intent -dependency
flutter pub add receive_intent

## To test this Project
first: you need to build and deploy this project to your android device, you can use the command
"flutter build apk" OR "flutter run"

Alternatively, this App is available in Google Play Store, so you need only to serach it and install it.

secondly: you need to let the other program to send an Intent to this program, here is what I use from MAUI written program

the intent should be constructed like this

String uri = "MAUI,<x>,...,<x>";
Where x is the string of type Base64String of your images

your usi should include at least one Base64String  of an image, thus it will looks like this: 
String uri = "MAUI,<x>";

Thats it, feel free to use the project if you feel to! : )

## To Do
send a reply to the calling program whether the printing is completed successfully or not 