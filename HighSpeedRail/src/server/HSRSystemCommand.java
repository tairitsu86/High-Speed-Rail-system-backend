package server;

import java.util.ArrayList;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

public enum HSRSystemCommand {
	HSRSC(),
	ERROR("Error","Decode error","JAVA",null,null,null,0),
	ConnectTest("ConnectTest","Connect test commend","JAVA",null,null,null,1),
	SQLTest("SQLTest","SQL Server connect test commend","SQL",null,null,null,2),
	SQLSelectTest("SelectTest","SQL Server select test commend","SQL",null,null,null,3),
	GetTrains0("GetTrains0","Get return ticket data","SQL",
			new String[] {"TicketPrice","Datas","BackDatas"},
			"EXEC [GetTrainsReturn] '%s','%s','%s','%s','%s','%s','%s','%s'",
			new String[] {"StartStation","ArriveStation","StartDate","StartTime","BackStartDate","BackStartTime","Type","Prefer"},
			10),
	GetTrains1("GetTrain1","Get oneway ticket data","SQL",
			new String[] {"TicketPrice","Datas"},
			"EXEC [GetTrainsOneWay] '%s','%s','%s','%s','%s','%s'",
			new String[] {"StartStation","ArriveStation","StartDate","StartTime","Type","Prefer"},
			11),
	CheckID("CheckID","Check ID and Data is mapping or not","SQL",
			new String[] {"New","Update"},
			"EXEC [CheckID] '%s', '%s','%s'",
			new String[] {"ID","Phone","Email"},
			20),
	Book0("Book0","Book return tickets","SQL",
			new String[] {"RecordID","GoSeat1","GoSeat2","GoSeat3","GoSeat4","GoSeat5","BackSeat1","BackSeat2","BackSeat3","BackSeat4","BackSeat5"},
			"EXEC BookReturn '%s','%s','%s','%s','%s',%s,'%s','%s','%s','%s'",
			new String[] {"ID","StartDate","BackDate","StartStation","ArriveStation","Tickets","Order","BackOrder","Type","Prefer"},
			30),
	Book1("Book1","Book oneway tickets","SQL",
			new String[] {"RecordID","GoSeat1","GoSeat2","GoSeat3","GoSeat4","GoSeat5"},
			"EXEC BookOneWay '%s','%s','%s','%s',%s,'%s','%s','%s'",
			new String[] {"ID","StartDate","StartStation","ArriveStation","Tickets","Order","Type","Prefer"},
			31),
	FindLose("FindLose","Find tickets by recordID and ID","SQL",
			new String[] {"OnewayReturn","Type","Tickets","Prices","Data1","Data2"},
			"EXEC [FindLose] '%s','%s'",
			new String[] {"ID","BookID"},
			50),
	FindCode("FindCode","Find recorID by some basic data","SQL",
			new String[] {"Datas"},
			"EXEC FindCode '%s','%s','%s','%s','%s'",
			new String[] {"StartStation","ArriveStation","StartDate","Order","ID"},
			60),
	Refund("Refund","Refund one ticket with the following datas","SQL",
			new String[]{"RefundResult"},
			"EXEC RefundTicket '%s','%s','%s'",
			new String[]{"BookID","Order","Seat"},
			80),
	Pay("Pay","Pay for tickets with recordID","SQL",
			new String[] {"PayResult"},
			"EXEC Pay '%s'",
			new String[] {"BookID"},
			90),
	Use("Use","Use ticket","SQL",
			new String[] {"UseResult"},
			"EXEC [Use] '%s','%s','%s'",
			new String[] {"BookID","Order","Seat"},
			100),
	Edit0("Edit0","Edit return ticket datas","SQL",
			new String[] {"GoSeat1","GoSeat2","GoSeat3","GoSeat4","GoSeat5","BackSeat1","BackSeat2","BackSeat3","BackSeat4","BackSeat5"},
			"EXEC EditReturn '%s','%s','%s','%s','%s'",
			new String[] {"BookID","StartDate","Order","BackDate","BackOrder"},
			110),
	Edit1("Edit1","Edit oneway ticket datas","SQL",
			new String[] {"GoSeat1","GoSeat2","GoSeat3","GoSeat4","GoSeat5"},
			"EXEC EditOneWay '%s','%s','%s'",
			new String[] {"BookID","StartDate","Order"},
			111),
	Take("Take","Take ticket","SQL",
			new String[]{"TakeResult"},
			"EXEC Take '%s','%s','%s'",
			new String[]{"BookID","Order","Seat"},
			120),
	HasTake("HasTake","Check the ticket been token or not","SQL",
			new String[]{"HasTakeResult"},
			"EXEC HasTake'%s','%s','%s'",
			new String[]{"BookID","Order","Seat"},
			130),
	PaidEdit0("PaidEdit","Edit return ticket","SQL",
			new String[]{"GoSeat","BackSeat"},
			"EXEC [PaidEditReturn] '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s','%s'",
			new String[]{"BookID","StartDate","BackDate","OriginOrder","OriginSeat","OriginBackOrder","OriginBackSeat","Order","BackOrder"},
			140),
	PaidEdit1("PaidEdit","Edit oneway ticket","SQL",
			new String[]{"GoSeat"},
			"EXEC [PaidEditOneway] '%s','%s','%s','%s','%s'",
			new String[]{"BookID","StartDate","OriginOrder","OriginSeat","Order"},
			141);
	private int id;
	private String name,description,type,column[],SQLQuery,SQLParameter[],errorMessage="Error";
	private JSONObject json,returnJson;
	private SQLServerDriverConnect ssdc = new SQLServerDriverConnect();
	private static final String FLAGS[] = new String[] {"OneWayReturn"};
	private HSRSystemCommand() {}
	private HSRSystemCommand(String name,String description,String type,String column[],String SQLQuery,String SQLParameter[],int id){
		this.name = name;
		this.description = description;
		this.type = type;
		this.column = column;
		this.SQLQuery = SQLQuery;
		this.SQLParameter = SQLParameter;
		this.id = id;
	}
	public HSRSystemCommand getCommandType(String jsonCommand) {
		JSONObject jsonTemp = (JSONObject)JSONValue.parse(jsonCommand);
		if(jsonTemp==null) {
			ERROR.errorMessage = String.format("{\"Status\": \"False\",\"Message\":\"Decode request error with following json:\n--------------------------------------------------\n%s\n--------------------------------------------------\n\"}", jsonCommand);
			return ERROR;
		}
		StringBuilder commandType = new StringBuilder("");
		for(int i=0,l=FLAGS.length;i<l;i++) {
			if(jsonTemp.get(FLAGS[i])==null) continue;
			if(jsonTemp.get(FLAGS[i]).toString().equals("True")) 
				commandType.append(1);
			else 
				commandType.append(0);
		}
		HSRSystemCommand cmd = HSRSystemCommand.valueOf(jsonTemp.get("CommandType").toString()+commandType.toString());
		cmd.json = jsonTemp;
		cmd.errorMessage = String.format("{\"Status\": \"False\",\"Message\":\"Decode request error with following json:\n--------------------------------------------------\n%s\n--------------------------------------------------\n\"}", jsonCommand);
		return cmd;
	}
	public String commandExecute() {
		if(this==ERROR) return errorMessage;
		returnJson = new JSONObject();
		returnJson.put("Status","False");
		if(SQLQuery!=null) 
			returnJson = SQLExecute(returnJson,SQLQuery,SQLParameter,column);
		if(returnJson==null) return errorMessage;
		returnJson.replace("Status","False", "True");
		return returnJson.toJSONString();
	}
	private JSONObject SQLExecute(JSONObject returnJson,String SQLQuery,String SQLParameter[],String column[]) {
		ArrayList<String[]> queryResult;
		String SQL = SQLQuery;
		for(int i=0,l=SQLParameter.length;i<l;i++) 
			SQL = CommandFormat(SQL, json.get(SQLParameter[i]).toString());
		System.out.println(SQL);
		queryResult = ssdc.connectWithReturn(SQL, column);
		if(queryResult==null) return null;
		for(int i=0,l=column.length;i<l;i++) {
			String temp = queryResult.get(0)[i];
			if(temp.length()>0&&temp.charAt(0)=='[') {
//				System.out.println(String.format("%s,\"%s\":%s}",returnJson.toJSONString().substring(0, returnJson.toJSONString().length()-1),column[i],temp));
				returnJson = (JSONObject)JSONValue.parse(String.format("%s,\"%s\":%s}",returnJson.toJSONString().substring(0, returnJson.toJSONString().length()-1),column[i],temp));
			}else {
				returnJson.put(column[i],temp);
			}
		}

		return returnJson;
	}
	private String CommandFormat(String command,String Parameter) {
		int cut = command.indexOf("%")+1;
		String subString1 = command.substring(0, cut),
				subString2 = command.substring(cut).replaceAll("%", "%%");
		return String.format(subString1+subString2, Parameter.replaceAll("'", "''"));
	}
	@Override
	public String toString() {
		return name+":"+description;
	}
	public String getName() {
		return name;
	}
	public String getDescription() {
		return description;
	}
	public String getType() {
		return type;
	}
	public int getID() {
		return id;
	}
}
