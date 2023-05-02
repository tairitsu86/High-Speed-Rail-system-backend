package server;

import java.lang.reflect.InvocationTargetException;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Properties;
import com.microsoft.sqlserver.jdbc.SQLServerResultSet;

public class SQLServerDriverConnect { 
//	localhost = 127.0.0.1 都是連接本機
	private String computerName = "localhost";
//	private String computerName = "127.0.0.1";
	
//	不確定用電腦名稱怎麼連過去的，猜測是在區域網路中尋找同名電腦，獲得IP，Android似乎不能連
//	private String computerName = "KIYOHIME";
	
//	用本機IP連線
//	在CMD輸入ipconfig，紀錄IPv4，那是本機能用的網路IP
//	然後開啟組態管理員，將該IP設定進去
//	private String computerName = "192.168.168.11";
	
//	10.0.2.2 在模擬器連接本機
//	private String computerName = "10.0.2.2";
	private String port = "1433";
	private String databaseName = "HighSpeedRail";
	private String user = "HRSConnect";
	private String password = "1234";
	private String URL;
	public ArrayList<String[]> connectWithReturn(String sql,String column[]){
		Driver d;
		ArrayList<String[]> result = new ArrayList<>();
		try {
			d = (Driver) Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver").getDeclaredConstructor().newInstance();
			try( Connection con = d.connect(getURL(), new Properties());
					Statement sta = con.createStatement();
					ResultSet rs = sta.executeQuery(sql)){
					String tmp[] = new String[column.length];
					while (rs.next()) {
						for(int i=0;i<column.length;i++) {
							if(rs.getObject(column[i])==null)
								tmp[i] = "";
							else
								tmp[i] = rs.getObject(column[i]).toString();
						}
						result.add(tmp);
					}
					return result;
				} catch (SQLException e) {
					e.printStackTrace();
					return null;
				}
		}catch(InstantiationException | IllegalAccessException | ClassNotFoundException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException | SecurityException e){
			e.printStackTrace();
			return null;
		}finally{
		}
	}
	public void connect(String sql){
		Driver d;
		try {
			d = (Driver) Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver").getDeclaredConstructor().newInstance();
			try( Connection con = d.connect(getURL(), new Properties());
				Statement sta = con.createStatement();){
				sta.execute(sql);
				} catch (SQLException e) {
					e.printStackTrace();
				}
		}catch(InstantiationException | IllegalAccessException | ClassNotFoundException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException | SecurityException e){
			e.printStackTrace();
		}finally{
		}
	}
	public static void main(String[] args) {
		SQLServerDriverConnect ssds = new SQLServerDriverConnect();
		
	}
	
	
	

	public String getComputerName() {
		return computerName;
	}
	public void setComputerName(String computerName) {
		this.computerName = computerName;
	}
	public String getPort() {
		return port;
	}
	public void setPort(String port) {
		this.port = port;
	}
	public String getDatabaseName() {
		return databaseName;
	}
	public void setDatabaseName(String databaseName) {
		this.databaseName = databaseName;
	}
	public String getUser() {
		return user;
	}
	public void setUser(String user) {
		this.user = user;
	}
	public String getPassword() {
		return password;
	}
	public void setPassword(String password) {
		this.password = password;
	}
	public String getURL() {
		setURL();
		return URL;
	}
	public void setURL() {
		URL = String.format("jdbc:sqlserver://%s%s%s%s%s%s%s%s%s", computerName, ":", port, ";databaseName=", databaseName, ";user=",user,";password=",password);
	}
}
