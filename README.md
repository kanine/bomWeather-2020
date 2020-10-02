# bomWeather - Work in Progress

bomWeather - Australian Weather Rainmeter Skin based on the Bureau of Meteorology data

Installation
============
1) Install Rainmeter from www.rainmeter.net
2) Download the latest release from GitHub, change file extension to rmskin
3) Open the file in Explorer to automatically import into Rainmeter
4) If using for the first time you will be prompted to run the setup script in the following location:
       Documents\Rainmeter\Skins\bomWeather-2020\@Resources\Scripts\bomWeatherSetup.vbs

Using The Script
================
First thing is to make sure you can see the Melbourne weather - which is the default. You should see this if you:

1) Start Rainmeter Client
2) Open the Rainmeter Manager and load the kanine bomWeather skin - 7DayForecast.ini
3) It may take a minute for the meters to refresh as the data is pulled from the bom.gov.au website
4) Once the default set up is working, run bomWeatherSetup.vbs and customise for your town and suburb.

Forecast not showing?
=====================
There will be a short delay the first time you open the script, the impatient among you can run the following script to update forecast information immediately:
        Documents\Rainmeter\Skins\bomWeather-2020\@Resources\Scripts\Rainmeter\bomWeather.vbs

If it still isn't working please raise an issue in Github or contact me via the Whirlpool Forums https://forums.whirlpool.net.au/forum-replies.cfm?t=1942286.

Notes
=====
Occasionally you may get a forecast icon of NA. This means the conversion of the forecast text is failing. Please raise an issue and paste the forecast text at the time and it should be a simple fix.

The phases of the moon csv was created with information from http://www.ga.gov.au, it will need to be updated annually for accurate results, it is currently based on FullMoon dates only and extrapolates the various phases from there.
