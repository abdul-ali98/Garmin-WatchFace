import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.ActivityMonitor;
using Toybox.Sensor;
using Toybox.Time.Gregorian as Date;

class McGillFaceView extends WatchUi.WatchFace {
  private var myImage;
  private var lastHR;

  function initialize() {
    WatchFace.initialize();

    myImage = Application.loadResource(Rez.Drawables.MyImage);
    lastHR = "";
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {}

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Get the current time and format it correctly
    var timeFormat = "$1$:$2$";
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    if (!System.getDeviceSettings().is24Hour) {
      if (hours > 12) {
        hours = hours - 12;
      }
    } else {
      if (getApp().getProperty("UseMilitaryFormat")) {
        timeFormat = "$1$$2$";
        hours = hours.format("%02d");
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
    var timeString = hoursString + ":" + minutesString;

    // Update the view
    var view = View.findDrawableById("TimeLabel") as Text;
    view.setColor(getApp().getProperty("ForegroundColor") as Number);
    view.setText(timeString);
    view.setLocation(
      dc.getWidth() / 2,
      dc.getHeight() / 4 - myImage.getHeight() / 4
    );
    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    dc.drawBitmap(dc.getWidth() / 4 + 1, dc.getHeight() / 4, myImage);
    dc.setColor(
      Graphics.COLOR_WHITE, // Using Blue as foreground color
      Graphics.COLOR_TRANSPARENT // Using transparent as background color
    );
        
        var batteryLabelView = View.findDrawableById("batteryLabel") as Text;
        var battery = System.getSystemStats().battery;
        var batteryString = battery.format("%.0f");
        batteryLabelView.setText(batteryString);
        
        var heartLabelView = View.findDrawableById("heartLabel") as Text;
        if (Activity.getActivityInfo() != null) {
          lastHR = Activity.getActivityInfo().currentHeartRate + "";
        }
        if (lastHR == null || lastHR == 0 || lastHR.equals("null")) {
           heartLabelView.setText("");
        }
          else { 
            heartLabelView.setText(lastHR); 
            }

    drawHand(dc, 60, minutes, 0.4 * dc.getWidth(), 3.5);
    drawHandOffset(dc, 12.0, 60.0, hours, minutes, 0.3 * dc.getWidth(), 3.5);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2, 3.5);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    drawDate(dc, 4, dc.getHeight() / 2);

  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {}

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {}

  function drawHand(dc, num, time, length, stroke) {
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
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;
    var section = 360.0 / num / offsetNum;

    angle += Math.toRadians(section * offsetTime);

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

  function drawDate(dc, x, y) {
    // Get the current time
    var now = Time.now();
    // Extract the date info, the strings will be localized
    var date = Date.info(now, Time.FORMAT_MEDIUM); // Extract the date info
    // Format the date into "ddd D", for instance: "Tue  6"
    var dateString = Lang.format("$1$ $2$", [date.day_of_week, date.day]);

    dc.drawText(
    x, // The x coordinate
    y, // The y coordinate
    Graphics.FONT_SMALL, // Using the default font with medium size
    dateString , // The text to draw
    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Justify to center both horizonatally and vertically using bitmap mask
    );
   }

    function drawTextBox(dc, text, x, y, width, height) {
		dc.setPenWidth(2);
    	
		var boxText = new WatchUi.Text({
            :text=>text,
            :color=>Graphics.COLOR_GREEN,
            :font=>Graphics.FONT_SMALL,
            :locX =>x ,
            :locY=>y,
			:justification=>Graphics.TEXT_JUSTIFY_LEFT
        });

		boxText.draw(dc);
	}

}
