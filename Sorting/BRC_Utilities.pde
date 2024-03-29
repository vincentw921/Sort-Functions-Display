import processing.net.*;

Server BRCServer;

int BRC_port = 10002;

String[] BRC_ids = new String[] {"DoIt","filename","dir","types","n","config"};
String[] BRC_values = new String[] {"0","","true","B","20","R"};

String[] BRC_Monitors = new String[] {"comps"};
String[] BRC_MonitorValues = new String[] {"N/A"};


ArrayList BRC_changed = new ArrayList();
boolean BRC_ShowMessages = false;
boolean BRC_Initialized = false;

void brcInit() {
  BRCServer = new Server(this,BRC_port);
  println("BRCFactory version 0.93");
  println("0. Create a small browser window.");
  println("1. Go to the url:  127.0.0.1:10002");
}

void brc() {
  if (!BRC_Initialized) {
    brcInit();
    BRC_Initialized = true;
  }
  brcServerRequest();
}

void brcServerRequest() {
    Client thisClient = BRCServer.available();
    if (thisClient != null) {
      if (thisClient.available() > 0) {
        String request = thisClient.readString();
        if (request.indexOf("favicon") > 0) {  // do not respond to request for favicon
          return;
        }
        if (request.indexOf("BRC::") == -1) { // request for html page
          //println(request);
          //String html = String.join("\n",loadStrings(BRC_Controls));
          //html = html.substring(html.indexOf("<")); // remove first non_ASCII char
          //String sendit = brcServerResponse(html);
          //thisClient.write(sendit);
          //println(sendit);

          brcSendWebpage(thisClient);
          
        }
        else {   // incoming change of control variable
          int pos = request.indexOf("BRC::")+5;
          int pos2 = request.indexOf("::",pos);
          if (pos2 < 0) {
            thisClient.write(brcServerResponse("Bad request"));
            println("Bad request",request);
          }
          else {
            String payload = request.substring(pos,pos2).trim();
            payload = brcDecode(payload);
            String response = brcParseRequest(payload);
            thisClient.write(brcServerResponse(response));
            //println("payload",payload);
          }
        }
        
      }
    }
}

String brcServerResponse(String s) {
  return (String.format("HTTP/1.1 200 OK\nContent-Length: %d\nContent-Type: text/html\n\n%s",s.length(),s));
}  

String brcParseRequest(String payload) {
    boolean found = false;
    int i;
    
  // if "MONITORS"
  if (payload.equals("MONITORS"))
      return brcMonitorsResponse();
      
  // otherwise should be name=value   
  int pos = payload.indexOf("=");
  if (pos < 0) {return "Bad request, no =";}
  String id = new String(payload.substring(0,pos));
  String value = new String(payload.substring(pos+1));
  if (BRC_ShowMessages)
      println(id+"="+value);
  for (i = 0; i < BRC_ids.length; ++i) {
    if (id.equals(BRC_ids[i])){
      BRC_values[i] = value;
      BRC_changed.add(id);
      found = true;
      break;
    }
  }
  if (!found)
      return "ID not found: |"+payload+"|";
  return brcMonitorsResponse();
}

String brcMonitorsResponse() {
  String mResponse = "**";
  if (BRC_Monitors.length == 0)
      return "OK";
  for (int i = 0; i < BRC_Monitors.length; ++i) {
      mResponse += BRC_Monitors[i]+"="+BRC_MonitorValues[i];
      if (i != BRC_Monitors.length - 1)
         mResponse += "][";
  }
  return mResponse;
}

String brcChanged() {
  if (BRC_changed.size() == 0) {return "";}
  return BRC_changed.remove(0).toString();
}

String brcValue(String id) {
  for (int i = 0; i < BRC_ids.length; ++i) {
    if (id.equals(BRC_ids[i])) {return BRC_values[i];}
  }
  return "";
}

void brcSetMonitor(String monitorName, String monitorValue) {
  boolean found = false;
  for (int i = 0; i < BRC_Monitors.length; ++i)
    if (BRC_Monitors[i].equals(monitorName)) {
      BRC_MonitorValues[i] = monitorValue;
      found = true;
      break;
    }
  if (!found)
    println("Monitor name not found: "+monitorName);
}

void brcSetMonitor(String monitorName, int monitorValue) {
    brcSetMonitor(monitorName, str(monitorValue));
}

void brcSetMonitor(String monitorName, float monitorValue, int digitsPrecision) {
    String prec = "%."+str(digitsPrecision)+"f";
    String val = String.format(prec,monitorValue);
    brcSetMonitor(monitorName,val);
}

String brcDecode(String s) {
   int i, n1, n2;
   String out = "";
   char c;
   
     i = 0;
     while (i < s.length()) {
       c = s.charAt(i);
       if (c != '%' || i > (s.length()-3))
         out = out + c;
       else {
         n1 = brcHexVal((char) s.charAt(i+1));
         n2 = brcHexVal((char) s.charAt(i+2));
         if (n1 == -1 || n2 == -1)
           out = out + c;
         else {
           out = out + (char) (16*n1+n2);
           i += 2;
         }
       }
       //println(out+" "+i);
       ++i;
     }
   return out;
}

int brcHexVal(char c) {
  String hex = "0123456789ABCDEFabcdef";
  int i;
  for (i = 0; i < hex.length(); ++i) {
    if (c == hex.charAt(i)) {
      if (i <= 15)
        return i;
      else
        return i-6;
    }
  }
  return -1;
}

void brcShowMessages(boolean which) {
    BRC_ShowMessages = which;
}

// =============================== Webpage========================
String BRC_Webpage = 
"HTTP/1.1 200 OK\n"
+ "Content-Length: 6248\n"
+ "Content-Type: text/html\n"
+ "\n"
+ "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
+ "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n"
+ "\n"
+ "<head>\n"
+ "<meta content=\"text/html; charset=utf-8\" http-equiv=\"Content-Type\" />\n"
+ "<title>BRC_Controls</title>\n"
+ "\n"
+ "<style type=\"text/css\">\n"
+ ".auto-style1 {\n"
+ "	border-color:red;\n"
+ "	border-width:1px;\n"
+ "	border-style:solid;\n"
+ "}\n"
+ ".monitor {\n"
+ "	border-color:blue;\n"
+ "	border-width:1px;\n"
+ "	border-style:solid;\n"
+ "}\n"
+ "</style>\n"
+ "\n"
+ "<script>\n"
+ "//----------------------- Sending --------------------------------------\n"
+ "function Send(url,results_id) {\n"
+ "  var xhttp = new XMLHttpRequest();\n"
+ "  xhttp.onreadystatechange = function() {\n"
+ "  	//alert(url);\n"
+ "    if (this.readyState == 4 && this.status == 200) {\n"
+ "      if (this.responseText.slice(0,2) != \"**\")\n"
+ "         document.getElementById(results_id).innerHTML = this.responseText;\n"
+ "      else {\n"
+ "         var result = UpdateMonitors(this.responseText.slice(2));\n"
+ "         document.getElementById(results_id).innerHTML = result;\n"
+ "      }\n"
+ "    }\n"
+ "  };\n"
+ "  xhttp.open(\"GET\", url, true);\n"
+ "  xhttp.send(null);\n"
+ "}\n"
+ "\n"
+ "function SendNameValue(name_value) {\n"
+ "	var url = \"127.0.0.1:\" + Port + \"/BRC::\" + name_value + \"::\";\n"
+ "	Send(url,'results');\n"
+ "}\n"
+ "\n"
+ "// ---------------------------- Monitors ----------------------------\n"
+ "var MonitorTicker = null;\n"
+ "\n"
+ "function StartMonitors() {\n"
+ "    if (Monitor) {\n"
+ "        MonitorTicker = setInterval(MonitorRequest,250);   // every 1/2 second\n"
+ "    }\n"
+ "}\n"
+ "\n"
+ "function MonitorRequest() {\n"
+ "    SendNameValue(\"MONITORS\");\n"
+ "}\n"
+ "        \n"
+ "function UpdateMonitors(incoming) {\n"
+ "    var pairs = incoming.split(\"][\");\n"
+ "    var i, j, pair, found;\n"
+ "    for (i = 0; i < pairs.length; ++i) {\n"
+ "        found = false;\n"
+ "        pair = pairs[i].split(\"=\");\n"
+ "        for (j = 0; j < Controls.length; ++j) {\n"
+ "            if (Controls[j][2] == pair[0]) { \n"
+ "                document.getElementById(Controls[j][1]).innerHTML = \"&nbsp;\"+pair[1]+\"&nbsp;\";\n"
+ "                found = true;\n"
+ "                break;\n"
+ "            }\n"
+ "        }\n"
+ "        if (!found)\n"
+ "            return \"Monitor not found: \"+pair[0]\n"
+ "    }\n"
+ "    return \"OK\"\n"
+ "}\n"
+ "\n"
+ "// ---------------------------------------------- Sendall and RangesInit ------------------------------\n"
+ "\n"
+ "const Port = 10002;\n"
+ "\n"
+ "// needed by Sendall() and RangesInit\n"
+ "\n"
+ "/*\n"
+ "Typical controls:\n"
+ "const Controls=[[\"RADIO\",\"brc_1\",\"shade\"],[\"DROPDOWN\",\"brc_4\",\"color\"],[\"CHECKBOX\",\"brc_5\",\"grayscale\"],\n"
+ "                [\"RANGE\",\"brc_6\",\"size\",\"brc_7\"],[\"TEXT\",\"brc_8\",\"title\"]];\n"
+ "\n"
+ "*/\n"
+ "\n"
+ "const Controls=[[\"NOTE\",\"brc_1\",\"warning\"],\n"
+ "[\"BUTTON\",\"brc_2\",\"DoIt\"],\n"
+ "[\"TEXT\",\"brc_3\",\"filename\"],\n"
+ "[\"CHECKBOX\",\"brc_4\",\"dir\"],\n"
+ "[\"DROPDOWN\",\"brc_5\",\"types\"],\n"
+ "[\"RANGE\",\"brc_6\",\"n\",\"brc_7\"],\n"
+ "[\"DROPDOWN\",\"brc_8\",\"config\"],\n"
+ "[\"MONITOR\",\"brc_9\",\"comps\"]];\n"
+ "\n"
+ "Monitor = true;\n"
+ "\n"
+ "function Sendall() {\n"
+ "	var i, opt;\n"
+ "	\n"
+ "	for (i = 0; i < Controls.length; ++i) {\n"
+ "		if (Controls[i][0] == \"RADIO\") {\n"
+ "			var rads = document.getElementsByName(Controls[i][1]);\n"
+ "			for (opt = 0; opt < rads.length; ++opt) {\n"
+ "				if (rads[opt].checked)\n"
+ "					SendNameValue(Controls[i][2]+\"=\"+rads[opt].value);\n"
+ "			}\n"
+ "		}\n"
+ "		else if (Controls[i][0] == \"DROPDOWN\" || Controls[i][0] == \"TEXT\") {\n"
+ "			SendNameValue(Controls[i][2]+\"=\"+document.getElementById(Controls[i][1]).value);\n"
+ "		}\n"
+ "		else if (Controls[i][0] == \"CHECKBOX\") {\n"
+ "			if (document.getElementById(Controls[i][1]).checked)\n"
+ "				SendNameValue(Controls[i][2]+\"=true\");\n"
+ "			else\n"
+ "				SendNameValue(Controls[i][2]+\"=false\");\n"
+ "		}\n"
+ "		else if (Controls[i][0] == \"RANGE\") {\n"
+ "			ShowRange(Controls[i][1],Controls[i][3],Controls[i][2]);\n"
+ "		}\n"
+ "	}\n"
+ "}\n"
+ "\n"
+ "\n"
+ "\n"
+ "// ------------------------------------ Individual senders ---------------------------------\n"
+ "function SendRadio(name_value) {\n"
+ "	//alert(name_value);\n"
+ "	SendNameValue(name_value);\n"
+ "}\n"
+ "\n"
+ "function SendCheckbox(id,brc_name) {\n"
+ "	if (document.getElementById(id).checked)\n"
+ "		SendNameValue(brc_name+'=true');\n"
+ "	else\n"
+ "		SendNameValue(brc_name+'=false');\n"
+ "}\n"
+ "\n"
+ "// ---------------------------------------- Utility functions -------------------------------\n"
+ "\n"
+ "function ShowRange(range_id,output_id,brc_name) {\n"
+ "	document.getElementById(output_id).innerHTML = document.getElementById(range_id).value;\n"
+ "	SendNameValue(brc_name+\"=\"+document.getElementById(range_id).value);\n"
+ "}\n"
+ "\n"
+ "\n"
+ "\n"
+ "</script>\n"
+ "\n"
+ "</head>\n"
+ "\n"
+ "<body onLoad=\"StartMonitors();\">\n"
+ "<form name=\"brc\">\n"
+ "\n"
+ "<table cellpadding=\"3\"><tr><td>\n"
+ "<table cellspacing=\"0\" ><tr><td>BRC Web Controls: &nbsp;&nbsp; </td>\n"
+ "<td class=\"auto-style1\"><label id=\"results\">OK</label></td></tr></table></td>\n"
+ "<td><input type=\"button\" name=\"sendall\" id=\"sendall\" value=\"Send all\" onclick=\"Sendall();\"/></td></tr></table>\n"
+ "\n"
+ "<table><tr><td><table><tr><td class=\"auto-style1\"><label id=\"brc_1\">Press SendAll button after settings</label></td></tr></table>\n"
+ "\n"
+ "</td><td><input type=\"button\" name=\"<!--<id>-->\" id=\"<!--<id>-->\" value=\"DoIt\" onClick=\"SendNameValue('DoIt='+Math.floor(Math.random()*1000000));\" />\n"
+ "&nbsp;&nbsp;&nbsp;\n"
+ "\n"
+ " </td><td><table ><tr><td class=\"auto-style1\">\n"
+ "Filename: <input type=\"text\" name=\"brc_3\" id=\"brc_3\" onchange=\"SendNameValue('filename='+document.getElementById('brc_3').value);\" /> \n"
+ "</td></tr></table>\n"
+ "\n"
+ "</td><td><table ><tr><td class=\"auto-style1\">\n"
+ "Send to SortDisplay?:  <input name=\"brc_4\" type=\"checkbox\" checked=\"checked\" id=\"brc_4\" onclick=\"SendCheckbox('brc_4','dir');\"/> \n"
+ "</td></tr></table>\n"
+ "\n"
+ "</td><td><table ><tr><td class=\"auto-style1\">Sort types:&nbsp;&nbsp;&nbsp;\n"
+ "<select name=\"brc_5\" id=\"brc_5\" onchange=\"SendNameValue('types='+document.brc.brc_5.value);\">\n"
+ "<option selected=\"selected\" value=\"B\">Bubble</option>\n"
+ "<option  value=\"I\">Insertion</option>\n"
+ "<option  value=\"S\">Selection</option>\n"
+ "</select></td></tr></table>\n"
+ "\n"
+ "</td><td><table ><tr><td class=\"auto-style1\">10  \n"
+ "    <input type=\"range\" id=\"brc_6\" name=\"brc_6\" min=\"10\" max=\"100\" value=\"20\" step=\"1\"\n"
+ "	oninput=\"ShowRange('brc_6','brc_7','n');\" />  100<br/>\n"
+ "	N elements: <label id=\"brc_7\"></label>\n"
+ "	</td></tr></table>\n"
+ "\n"
+ "</td><td><table ><tr><td class=\"auto-style1\">Pre-ordered?:&nbsp;&nbsp;&nbsp;\n"
+ "<select name=\"brc_8\" id=\"brc_8\" onchange=\"SendNameValue('config='+document.brc.brc_8.value);\">\n"
+ "<option selected=\"selected\" value=\"R\">Random</option>\n"
+ "<option  value=\"S\">Sorted</option>\n"
+ "<option  value=\"V\">Reverse</option>\n"
+ "</select></td></tr></table>\n"
+ "\n"
+ "</td><td><table><tr><td class=\"auto-style1\">Comparisons <label id=\"brc_9\" class=\"monitor\">N/A</label>\n"
+ "</td></tr></table>\n"
+ "\n"
+ "</td></tr></table>\n"
+ "\n"
+ "\n"
+ "</form>\n"
+ "</body>\n"
+ "</html>\n";

// =============================== End webpage ===================
void brcSendWebpage(Client client) {
    client.write(BRC_Webpage);
}
