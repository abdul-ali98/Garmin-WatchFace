import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
using Toybox.UserProfile;
import Toybox.WatchUi;
using Toybox.ActivityMonitor;
using Toybox.Sensor;
using Toybox.Time;
using Toybox.Math;
using Toybox.Position;
using Toybox.Weather;
using Toybox.Time.Gregorian as Date;

class McGillFaceView extends WatchUi.WatchFace {
  private var mcGillImage;
  private var lastHR;
  private var weather_icon_snow;
  private var weather_icon_normal;
  private var weather_icon_worst;
  private var flip; // for the time label to show/hide the ":"
  private var isSleep; // we update it so we do not draw the seconds arc in low mode
  var heartLabelView;

  var lowTemperature;
  var highTemperature;
  var sunriseTime;
  var sunsetTime;
  var runningDistance = 0;
  var cyclingDistance = 0;
  var swimmingDistance = 0;

  public function initialize() {
    WatchFace.initialize();

    // We use mcGillImage to determine the time label position
    mcGillImage = Application.loadResource(Rez.Drawables.mcgill_logo);
    weather_icon_snow = Application.loadResource(
      Rez.Drawables.weather_icon_snow
    );
    weather_icon_normal = Application.loadResource(
      Rez.Drawables.weather_icon_normal
    );
    weather_icon_worst = Application.loadResource(
      Rez.Drawables.weather_icon_worst
    );
    lastHR = "--";
    sunriseTime = "--:--";
    sunsetTime = "--:--";
    flip = false;
    isSleep = false;

    setSportsDistance();
    setSunTimes();
  }

  // We load resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  /**
   * Gets called in low battery mode every second
   * However, it has to be fast and never exceeds 100ms in execution on average
   */
  function onPartialUpdate(dc as Dc) as Void {
    if (Activity.getActivityInfo() != null) {
      lastHR = Activity.getActivityInfo().currentHeartRate + "";
    }
    if (lastHR == null || lastHR == 0 || lastHR.equals("null")) {
      lastHR = "--";
    }
    heartLabelView.setText(lastHR);
  }

  /**
   * Update time label every second, we support 24H and 12H systems based on user's perefrences
   */
  function drawTime(dc) {
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    if (!System.getDeviceSettings().is24Hour && hours > 12) {
      hours = hours - 12;
    }

    var hoursString = hours + "";

    if (hours < 10) {
      hoursString = "0" + hours;
    }
    var minutes = clockTime.min.format("%02d").toLong();
    var minutesString = minutes;
    if (minutes < 10) {
      minutesString = "0" + minutes;
    }
    var timeString =
      hoursString + (flip || isSleep ? ":" : " ") + minutesString;
    flip = !flip;
    // Update the view
    var view = View.findDrawableById("TimeLabel") as Text;
    view.setColor(Graphics.COLOR_RED);
    view.setText(timeString);
    view.setLocation(
      dc.getWidth() / 2,
      dc.getHeight() / 4 - mcGillImage.getHeight() / 5
    );
    View.onUpdate(dc);
  }

  /**
   * Update battery level every second.
   * TODO Should we update it everytime the face gets initialized for optimization?
   */
  function drawBattery(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var batteryLabelView = View.findDrawableById("batteryLabel") as Text;
    var systemStats = System.getSystemStats();
    var battery = systemStats.battery;
    var batteryString = battery.format("%.0f") + "%";
    batteryLabelView.setText(batteryString);
  }
  /**
   * Update heart rate value and make sure the value is valid
   */
  function drawHeartRate(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    heartLabelView = View.findDrawableById("heartLabel") as Text;
    if (Activity.getActivityInfo() != null) {
      lastHR = Activity.getActivityInfo().currentHeartRate + "";
    }

    // If the watch is charging, it means that if the data is available => inaccurant
    if (
      System.getSystemStats().charging ||
      lastHR == null ||
      lastHR == 0 ||
      lastHR.equals("null")
    ) {
      lastHR = "...";
    }
    heartLabelView.setText(lastHR);
  }

  /**
   * This method draw an arc to represent the seconds. Gets updated iff watch is not in low mode
   */

  function drawSecondsArc(dc) {
    var seconds = System.getClockTime().sec;
    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); // Using red as foreground color
    if (!isSleep) {
      dc.drawArc(
        dc.getWidth() / 2,
        dc.getWidth() / 2,
        dc.getWidth() / 2,
        Graphics.ARC_CLOCKWISE,
        90,
        seconds <= 15 ? 90 - (360 / 60) * seconds : ((15 - seconds) * 360) / 60
      );
    }
  }

  /**
   * Update the weather tempratures for the day (low, high)
   * and updates the weather icon based on the current weather
   */
  function drawWeather(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var dailyForecast = Weather.getDailyForecast();

    if (
      dailyForecast == null ||
      dailyForecast.size() < 1 ||
      dailyForecast[0].lowTemperature == null ||
      dailyForecast[0].highTemperature == null
    ) {
      // Use the old data
      if (lowTemperature != null && highTemperature != null) {
        drawWeatherHelper(dc, lowTemperature, highTemperature);
      } else {
        drawWeatherHelper(dc, "--", "--");
      }
    } else {
      // Update new values
      lowTemperature = dailyForecast[0].lowTemperature;
      highTemperature = dailyForecast[0].highTemperature;

      drawWeatherHelper(dc, lowTemperature, highTemperature);
    }
  }

  /**
   * Updates Sunrise and sunrise labels
   * Assumes the data is available piror call
   */
  function drawSunTimes(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var label = View.findDrawableById("sunriseLabel") as Text;
    label.setText(sunriseTime);
    label = View.findDrawableById("sunsetLabel") as Text;
    label.setText(sunsetTime);
  }

  // Update the view every second if not in low mode
  function onUpdate(dc as Dc) as Void {
    // Get the current time and format it correctly
    View.onUpdate(dc);
    drawTime(dc);
    drawBattery(dc);
    drawHeartRate(dc);
    drawSportsDistance(dc);
    drawLines(dc);
    drawDate(dc);
    drawSecondsArc(dc);
    drawWeather(dc);
    drawSteps(dc);
    drawSunTimes(dc);

    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var minutes = clockTime.min.format("%02d").toLong();
    
    // Has to be at the end so they will be on top of all drawings
    drawHand(dc, 60, minutes, 0.4 * dc.getWidth(), 4.5);
    drawHandOffset(dc, 12.0, 60.0, hours, minutes, 0.3 * dc.getWidth(), 4.5);
  }

  function drawSportsDistance(dc) {
    var totalDistance = 0;
    
    if (Application.getApp().getProperty("UseRunDistance")) {
      totalDistance += runningDistance;
    }
    if (Application.getApp().getProperty("UseBikeDistance")) {
      totalDistance += cyclingDistance;
    }
    if (Application.getApp().getProperty("UseSwimDistance")) {
      totalDistance += swimmingDistance;
    }

    var sportsDistance = "" + (totalDistance/1000);
    var distanceLabelView = View.findDrawableById("sportDistanceLabel") as Text;
    distanceLabelView.setText(sportsDistance + " KM");
  }

  function drawWeatherHelper(dc, lowTemp, highTemp) {
    if (
      !lowTemp.equals("--") &&
      System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE
    ) {
      lowTemp = (lowTemp * 9) / 5 + 32;
      lowTemp = lowTemp.format("%02d");
      highTemp = (highTemp * 9) / 5 + 32;
    }
    
    var lowTempeString = lowTemp + "\u00B0";
    var highTempString = highTemp + "\u00B0";
    while (highTempString.length() < 3) {
      highTempString = " " + highTempString;
    }
    while (lowTempeString.length() < 3) {
      lowTempeString = " " + lowTempeString;
    }

    var lowTempLabelView = View.findDrawableById("weatherLabel1") as Text;
    lowTempLabelView.setText(lowTempeString);

    dc.setPenWidth(2);
    dc.drawLine(45, 78, 60, 68);

    var highTempLabelView = View.findDrawableById("weatherLabel2") as Text;
    highTempLabelView.setText(highTempString);

    var h = dc.getHeight() / 3.5f;
    if (Weather.getCurrentConditions() != null) {
      var condition = Weather.getCurrentConditions().condition;

      switch (condition) {
        case Weather.CONDITION_CHANCE_OF_SHOWERS:
        case Weather.CONDITION_HEAVY_RAIN:
        case Weather.CONDITION_HEAVY_SHOWERS:
        case Weather.CONDITION_HURRICANE:
        case Weather.CONDITION_SANDSTORM:
        case Weather.CONDITION_THUNDERSTORMS:
          dc.drawBitmap(20, h, weather_icon_worst);
          break;
        case Weather.CONDITION_CHANCE_OF_SNOW:
        case Weather.CONDITION_SNOW:
        case Weather.CONDITION_LIGHT_SNOW:
          dc.drawBitmap(20, h, weather_icon_snow);
          break;
        default:
          dc.drawBitmap(20, h, weather_icon_normal);
          break;
      }
    } else {
      dc.drawBitmap(20, h, weather_icon_normal);
    }
  }
  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {
    isSleep = false;
  }

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {
    isSleep = true;
  }

  /**
   * Makes the necessary calls to draw the lines that seprate each data field
   */
  function drawLines(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    dc.setPenWidth(1);
    var fontHeight = Graphics.getFontHeight(Graphics.FONT_MEDIUM);
    var center = dc.getWidth() / 2;

    // Four horizonal lines, same on all devices
    var h1 = 0;
    var h2 = 0;
    if (dc.getWidth() == 260) {
      h1 = 85;
      h2 = 175;
    } else if (dc.getWidth() == 240) {
      h1 = 75;
      h2 = 165;
    }
    dc.drawLine(10, center + fontHeight / 2, h1, center + fontHeight / 2); 
    dc.drawLine(10, center - fontHeight / 2, h1, center - fontHeight / 2);
    dc.drawLine(
      h2,
      center + fontHeight / 2,
      dc.getWidth() - 10,
      center + fontHeight / 2
    );
    dc.drawLine(
      h2,
      center - fontHeight / 2,
      dc.getWidth() - 10,
      center - fontHeight / 2
    );

    /* For debugging 
      dc.drawLine(center - 45,center - 45, center - 45, center + 45);
      dc.drawLine(center + 45,center - 45, center + 45, center + 45);
      dc.drawLine(center- 45,center - 45, center + 45, center - 45);
      dc.drawLine(center - 45,center + 45, center + 45, center + 45); */

    var length = dc.getWidth() / 3.5;
    drawHandCut(dc, 60 /* constant = 60 */, 6 /* minutes */, length, 2);
    drawHandCut(dc, 60 /* constant = 60 */, 54 /* minutes */, length, 2);

    drawHandCut(dc, 60 /* constant = 60*/, 25 /* minutes */, length, 2);
    drawHandCut(dc, 60 /*constant = 60 */, 35 /* minutes */, length, 2);
  }

  /**
   * Draw a hand that do not start from the center.
   *
   */
  function drawHandCut(dc, num /* 60 */, time /* minutes */, length, stroke) {
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x1 = center + Math.round(Math.cos(angle) * 45 * Math.sqrt(2));
    var y1 = center + Math.round(Math.sin(angle) * 45 * Math.sqrt(2));
    var x2 = x1 + Math.round(Math.cos(angle) * length);
    var y2 = y1 + Math.round(Math.sin(angle) * length);

    dc.drawLine(x1, y1, x2, y2);
  }

  /**
   * Draw watch hand, num should be 60 obviously
   */
  function drawHand(dc, num /* 60 */, time /* minutes */, length, stroke) {
    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;
    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

  /**
      For Hours, i.e if the time is 9:30, we need the hour hand to be in between 9 and 10
    */
  function drawHandOffset(
    dc,
    num,
    offsetNum,
    time,
    offsetTime,
    length,
    stroke
  ) {
    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;
    var section = 360.0 / num / offsetNum;

    angle += Math.toRadians(section * offsetTime);

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    // Math.round() returns +ve or -ve
    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

  /**
   * We update the value of the Date label
   */
  function drawDate(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    // Get the current time
    var now = Time.now();
    // Extract the date info, the strings will be localized
    var date = Date.info(now, Time.FORMAT_MEDIUM); // Extract the date info
    // Format the date into "ddd D", for instance: "Tue  6"
    var dateString = Lang.format("$1$ $2$", [date.day_of_week, date.day]);

    var label = View.findDrawableById("dateLabel") as Text;
    label.setText(dateString);
  }

  /**
   * We compute the distance of running, cycling and swimming of the user,
   * then, we show the total distance of their prefered sports according
   * to their settings
   */
  function setSportsDistance() {
    var userActivityIterator = UserProfile.getUserActivityHistory();
    runningDistance = 0;
    cyclingDistance = 0;
    swimmingDistance = 0;

    var sample = null;
    if (userActivityIterator != null) {
      sample = userActivityIterator.next();
    }

    var startOfWeek = getTimeStampForStartOfWeek();

    while (sample != null) {
      if (sample.distance != null && sample.startTime.value() > startOfWeek) {
        if (sample.type == Activity.SPORT_RUNNING) {
          runningDistance += sample.distance;
        } else if (sample.type == Activity.SPORT_CYCLING) {
          cyclingDistance += sample.distance;
        } else if (sample.type == Activity.SPORT_SWIMMING) {
          swimmingDistance += sample.distance;
        }
      }
      sample = userActivityIterator.next();
    }
  }

  /**
   * This is purposely not documented
   */
  function getTimeStampForStartOfWeek() {
    var todayTime = new Time.Moment(Time.today().value());
    var todayDate = Date.info(todayTime, Time.FORMAT_SHORT);
    var dayOfWeek = todayDate.day_of_week;
    var userFirstDayOfWeek = System.getDeviceSettings().firstDayOfWeek;
    var oneDay = new Time.Duration(24 * 60 * 60);
    var startOfWeek = 0;
   /* System.println(
      "user: " +
        userFirstDayOfWeek +
        "; 7 - user - dayOfweek: " +
        (7 - userFirstDayOfWeek - dayOfWeek)
    );
    System.println("dayOfWeek: " + dayOfWeek); */
    if (userFirstDayOfWeek > dayOfWeek) {
      startOfWeek = new Time.Moment(
        todayTime.value() -
          ((7 - (userFirstDayOfWeek - dayOfWeek)) * oneDay.value() +
            todayDate.hour * 60 * 60 +
            todayDate.min * 60)
      );
    } else {
      startOfWeek = new Time.Moment(
        todayTime.value() -
          ((dayOfWeek - userFirstDayOfWeek) * oneDay.value() +
            todayDate.hour * 60 * 60 +
            todayDate.min * 60)
      );
    }
    System.println(startOfWeek.value());
    return startOfWeek.value();
  }
  /**
   * We update the value of the steps label
   */
  function drawSteps(dc) {
    var info = ActivityMonitor.getInfo();
    var steps = info.steps;
    var stepsString = steps + "";
    while (stepsString.length() < 4) {
      stepsString = " " + stepsString;
    }
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color

    var label = View.findDrawableById("stepsLabel") as Text;
    label.setText(stepsString);
  }

  /**
   * we get sunrise and sunrise times which is available iff location info is available too.
   * Then we store the sun times in storage so it will be available and valid for few days
   * TODO check if the sun times have expired in 7 days.
   */
  function setSunTimes() {
    var sunrise_moment = null;
    var sunset_moment = null;
    var locationInfo = Position.getInfo();

    // Location is necessary to get sunrise and sunset times
    if (
      locationInfo != null &&
      locationInfo.accuracy != Position.QUALITY_NOT_AVAILABLE
    ) {
      var loc = locationInfo.position;
      sunrise_moment = Weather.getSunrise(loc, Time.today());
      sunset_moment = Weather.getSunset(loc, Time.today());
    }
    if (sunrise_moment != null) {
      var sunrise_info = Time.Gregorian.info(
        new Time.Moment(sunrise_moment.value()),
        Time.FORMAT_SHORT
      );
      var hours = sunrise_info.hour;
      if (!System.getDeviceSettings().is24Hour) {
        hours = hours % 12;
      }
      sunriseTime = hours.format("%02d") + ":" + sunrise_info.min.format("%02d");

      // We store the sunTimes since it will be valid for few days before it needs to be updated.
      Application.Storage.setValue("sunrise", sunriseTime);
    } else if (Application.Storage.getValue("sunrise") != null) {
      sunriseTime = Application.Storage.getValue("sunrise");
    }
    if (sunset_moment != null) {
      var sunset_info = Time.Gregorian.info(
        new Time.Moment(sunset_moment.value()),
        Time.FORMAT_SHORT
      );
      var hours = sunset_info.hour;
      if (!System.getDeviceSettings().is24Hour) {
        hours = hours % 12;
      }
      sunsetTime = hours.format("%02d") + ":" + sunset_info.min.format("%02d");
      Storage.setValue("sunset", sunsetTime);
    } else if (Application.Storage.getValue("sunset") != null) {
      sunsetTime = Application.Storage.getValue("sunset");
    }
  }
}
//! Receives watch face events
class McGillDelegate extends WatchUi.WatchFaceDelegate {
  private var _view as McGillFaceView;

  //! Constructor
  //! @param view The analog view
  public function initialize(view as McGillFaceView) {
    WatchFaceDelegate.initialize();
    _view = view;
  }

  /**
   * Gets called if we exceed power budget in onPartialUpdates()
   */
  //! @param powerInfo Information about the power budget
  public function onPowerBudgetExceeded(
    powerInfo as WatchFacePowerInfo
  ) as Void {
    System.println("Average execution time: " + powerInfo.executionTimeAverage);
    System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
    //  _view.turnPartialUpdatesOff();
  }
}
