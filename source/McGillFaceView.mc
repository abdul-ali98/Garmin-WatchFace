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
  private var isSleep;
  var heartLabelView;

  var lowTemperature;
  var highTemperature;
  var sunriseTime;
  var sunsetTime;
  var sportDistance;

  public function initialize() {
    // Least common multipler for 218, 240, 260, 360, 416, 454 is 463,188,960;

    WatchFace.initialize();

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

    getActivityDistance();
    setSunTimes();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  function onPartialUpdate(dc as Dc) as Void {
    //   var seconds =  System.getClockTime().sec;

    if (Activity.getActivityInfo() != null) {
      lastHR = Activity.getActivityInfo().currentHeartRate + "";
    }
    if (lastHR == null || lastHR == 0 || lastHR.equals("null")) {
      lastHR = "--";
    }
    heartLabelView.setText(lastHR);
  }

  function drawTime(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var timeFormat = "$1$:$2$";
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var seconds = clockTime.sec;
    if (!System.getDeviceSettings().is24Hour) {
      if (hours > 12) {
        hours = hours - 12;
      }
    }
    var hoursString = hours;

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
    var h = dc.getHeight() / 4 - mcGillImage.getHeight() / 5;
  }

  function drawLogo(dc) {
 //    dc.drawBitmap(dc.getWidth() / 4 , dc.getHeight() / 4, mcGillImage);

    System.print("Logo is called");
    //This is a scaled Bitmap so we can adjust the logo to the screen size
 /*   dc.drawScaledBitmap(
      dc.getWidth() / 4,
      dc.getHeight() / 4,
      dc.getWidth() / 2,
      dc.getWidth() / 2,
      mcGillImage
    ); */
  }

  function drawBattery(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var batteryLabelView = View.findDrawableById("batteryLabel") as Text;
    var systemStats = System.getSystemStats();
    var battery = systemStats.battery;
    var batteryString = battery.format("%.0f") + "%";
    batteryLabelView.setText(batteryString);

  }

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
    var iconDimension = dc.getWidth() / 6.5;

    heartLabelView.setText(lastHR);
  }

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

  function drawSunTimes(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var label = View.findDrawableById("sunriseLabel") as Text;
    label.setText(sunriseTime);
    label = View.findDrawableById("sunsetLabel") as Text;
    label.setText(sunsetTime);
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Get the current time and format it correctly
    View.onUpdate(dc);
    drawTime(dc); 

    drawBattery(dc); 
    drawHeartRate(dc);

    var distanceLabelView = View.findDrawableById("sportDistanceLabel") as Text;
    distanceLabelView.setText(sportDistance + " KM");

    var timeFormat = "$1$:$2$";
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var seconds = clockTime.sec;
    var minutes = clockTime.min.format("%02d").toLong();
    drawLines(dc); 

    drawDate(dc); 
    drawSecondsArc(dc); 
    drawWeather(dc);
    drawSteps(dc);
    drawSunTimes(dc);

    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    drawHand(dc, 60, minutes, 0.4 * dc.getWidth(), 4.5);
    // drawHand2(dc, 360/minutes, 4.5, 0.4 * dc.getWidth());
    drawHandOffset(dc, 12.0, 60.0, hours, minutes, 0.3 * dc.getWidth(), 4.5);
    //  View.onUpdate(dc);
  }

  function drawWeatherHelper(dc, lowTemp, highTemp) {
    if (
      !lowTemperature.equals("--") &&
      System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE
    ) {
      lowTemp = (lowTemp * 9) / 5 + 32;
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
    highTempLabelView.setText(lowTempeString);

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
    dc.drawLine(10, center + fontHeight / 2, h1, center + fontHeight / 2); // x2 was 85
    dc.drawLine(10, center - fontHeight / 2, h1, center - fontHeight / 2);
    dc.drawLine(h2, center + fontHeight / 2, dc.getWidth() -10, center + fontHeight / 2);
    dc.drawLine(h2, center - fontHeight / 2, dc.getWidth() -10, center - fontHeight / 2);

    /*  dc.drawLine(center - 45,center - 45, center - 45, center + 45);
      dc.drawLine(center + 45,center - 45, center + 45, center + 45);
      dc.drawLine(center- 45,center - 45, center + 45, center - 45);
      dc.drawLine(center - 45,center + 45, center + 45, center + 45); */

    var length = dc.getWidth() / 3.5;
    drawHandCut(dc, 60 /* constant = 60 */, 5 /* minutes */, length, 2);
    drawHandCut(dc, 60 /* constant = 60 */, 55 /* minutes */, length, 2);

    drawHandCut(dc, 60 /* constant = 60*/, 25 /* minutes */, length, 2);
    drawHandCut(dc, 60 /*constant = 60 */, 35 /* minutes */, length, 2);
  }

  function drawHandCut(dc, num /* 60 */, time /* minutes */, length, stroke) {
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x1 = center + Math.round(Math.cos(angle) * 45 * Math.sqrt(2));
    var y1 = center + Math.round(Math.sin(angle) * 45 * Math.sqrt(2));
    var x2 = x1 + Math.round(Math.cos(angle) * length);
    var y2 = y1 + Math.round(Math.sin(angle) * length);

    dc.drawLine(x1, y1, x2, y2);
  }

  //! Draw the watch hand
  //! @param dc Device Context to Draw
  //! @param angle Angle to draw the watch hand
  //! @param length Length of the watch hand
  //! @param width Width of the watch hand
  function drawHand2(dc, angle, length, width) {
    // Map out the coordinates of the watch hand
    var coords = [
      [-(width / 2), 0],
      [-(width / 2), -length],
      [width / 2, -length],
      [width / 2, 0],
    ];
    var result = new [4];
    var centerX = dc.getWidth() / 2;
    var centerY = dc.getHeight() / 2;
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);

    //System.println("coord has:" + coords[0] + "  " + coords[1]);
    // Transform the coordinates
    for (var i = 0; i < 4; i += 1) {
      var x = coords[0] * cos - coords[1] * sin;
      var y = coords[0] * sin + coords[1] * cos;
      result = [centerX + x, centerY + y];
    }

    // Draw the polygon
    dc.fillPolygon(result);
    dc.fillPolygon(result);
  }
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

    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

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
    System.println(
      "Date label has width: " + View.findDrawableById("dateLabel").width
    );
  }

  function drawTextBox(dc, text, x, y, width, height) {
    dc.setPenWidth(2);

    var boxText = new WatchUi.Text({
      :text => text,
      :color => Graphics.COLOR_GREEN,
      :font => Graphics.FONT_SMALL,
      :locX => x,
      :locY => y,
      :justification => Graphics.TEXT_JUSTIFY_LEFT,
    });

    boxText.draw(dc);
  }

  function getActivityDistance() {
    var distance = getRunningDistance();
    sportDistance = "" + distance / 1000;
  }

  function getRunningDistance() as Number {
    var userActivityIterator = UserProfile.getUserActivityHistory();
    var distance = 0;

    var sample = null;
    if (userActivityIterator != null) {
      sample = userActivityIterator.next();
    }

    var todayTime = new Time.Moment(Time.today().value());
    var todayDate = Date.info(todayTime, Time.FORMAT_SHORT);
    var dayOfWeek = todayDate.day_of_week;
    var userFirstDayOfWeek = System.getDeviceSettings().firstDayOfWeek;
    var oneDay = new Time.Duration(24 * 60 * 60);
    var startOfWeek = 0;
    System.println(
      "user: " +
        userFirstDayOfWeek +
        "; 7 - user - dayOfweek: " +
        (7 - userFirstDayOfWeek - dayOfWeek)
    );
    System.println("dayOfWeek: " + dayOfWeek);
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
    while (sample != null) {
      if (sample.distance != null) {
        if (sample.startTime.value() > startOfWeek.value()) {
          if (sample.type == Activity.SPORT_RUNNING) {
            distance += sample.distance;
          }
        }
      }
      sample = userActivityIterator.next();
    }
    return distance;
  }
  function drawSteps(dc) {
    var info = ActivityMonitor.getInfo();
    var steps = info.steps;
    var stepsString = steps + "";
    while (stepsString.length() < 4) {
      stepsString = " " + stepsString;
    }
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color

    var x = (dc.getWidth() * 3) / 4 - 15;

    var label = View.findDrawableById("stepsLabel") as Text;
    label.setText(stepsString);

    //   dc.drawBitmap(210, 70, steps_icon);
  }
  function setSunTimes() {
    var sunrise_moment = null;
    var sunset_moment = null;
    var locationInfo = Position.getInfo();
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
      sunriseTime =
        hours.format("%02d") + ":" + sunrise_info.min.format("%02d");
      Application.Storage.setValue("sunrise", sunriseTime);
    } else if (Application.Storage.getValue("sunrise") != null) {
      sunriseTime = Application.Storage.getValue("sunrise");
      System.println("frommmmm time isdddd:");
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
      System.println("sun set time is:" + sunsetTime);
      Storage.setValue("sunset", sunsetTime);
    } else if (Application.Storage.getValue("sunset") != null) {
      sunsetTime = Application.Storage.getValue("sunset");
      System.println("frommmmm time is:");
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

  //! @param powerInfo Information about the power budget
  public function onPowerBudgetExceeded(
    powerInfo as WatchFacePowerInfo
  ) as Void {
    System.println("Average execution time: " + powerInfo.executionTimeAverage);
    System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
    //  _view.turnPartialUpdatesOff();
  }
}
