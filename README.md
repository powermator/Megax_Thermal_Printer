This Flutter App serves as a Passive thermal-print service for any other App that need to use thermal printing capabilities.
Passive means you dont need to run it, it is fired by android Intents.

The usage is very simple and as follows:
as soon as you send an intent to this program - note that your intent should include 1. path of an image needs to be printed 2. MAC of the thermal device- , the program will connect to the thermal printer via bluetooth and give the printing order.
Ultimately the program sends a reply intent when the printing is done and close itself. 


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
flutter build apk.

secondly: you need to let the other program to send an Intent to this program, here is what I use from MAUI written program
try
{
    Intent sendIntent = new Intent();
    sendIntent.SetAction(Intent.ActionSend);
    sendIntent.SetAction("RECEIVE_INTENT_EXAMPLE_ACTION");
    sendIntent.PutExtra(Intent.ExtraText, "text from MAUI");
    MainActivity.StartActivity(sendIntent);
}
catch (Exception ex) { };

Thats it, feel free to use the project if you feel to! : )
