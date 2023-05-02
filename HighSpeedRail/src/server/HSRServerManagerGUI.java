package server;

import java.awt.EventQueue;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JLabel;
import java.awt.Font;
import javax.swing.JTextField;
import javax.swing.DefaultListModel;
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.awt.event.ActionEvent;
import javax.swing.JTextArea;
import javax.swing.JScrollPane;
import javax.swing.ListSelectionModel;

public class HSRServerManagerGUI extends JFrame {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private JPanel contentPane;
	private JLabel lb_serverName;
	private JLabel lb_port;
	private JTextField tf_serverName;
	private JTextField tf_port;
	private JButton btn_createServer;
	private JList<ServerListItem> serverList;
	private DefaultListModel<ServerListItem> serverListItems = new DefaultListModel<ServerListItem>();
	private JScrollPane scrollPane;
	private JLabel lblNewLabel;
	private JLabel lb_detail;
	private JButton btn_removeServer;
	private JButton btn_serverStart;
	private JScrollPane scrollPane_1;
	private JTextArea ta_systemMessage;
	private JLabel lblNewLabel_1;
	private JScrollPane scrollPane_2;
	private JLabel lblNewLabel_2;
	private JButton btn_refresh;
	private JTextArea ta_connectMessage;
	/**
	 * Use for get connect message for server,if this BlockingQueue is full,
	 * the program will stuck because server can't put data into BlockingQueue,
	 * so we need take the data regularly and enough fast to prevent it full.
	 * Now BlockingQueue size is 10000, and refresh frequency is 1 times/second,
	 * so the maximum connect number per second is 10000.(FOR ALL SERVER)
	 */
	private final static int SIZE = 10000;
	private final static int REFERSHTIME = 1000;
	public static BlockingQueue<String> connectMessage = new ArrayBlockingQueue<>(SIZE);
	private JLabel lblNewLabel_3;
	private JButton btn_stopCM;
	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					HSRServerManagerGUI frame = new HSRServerManagerGUI();
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the frame.
	 */
	public HSRServerManagerGUI() {
		setResizable(false);
		setTitle("High Speed Rail Connect Server Manager");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 1000, 460);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		contentPane.setLayout(null);
		
		lb_serverName = new JLabel("Server Name:");
		lb_serverName.setFont(new Font("新細明體", Font.PLAIN, 16));
		lb_serverName.setBounds(92, 220, 87, 28);
		contentPane.add(lb_serverName);
		
		lb_port = new JLabel("Port:");
		lb_port.setFont(new Font("新細明體", Font.PLAIN, 16));
		lb_port.setBounds(92, 258, 78, 28);
		contentPane.add(lb_port);
		
		tf_serverName = new JTextField();
		tf_serverName.setBounds(189, 224, 96, 21);
		contentPane.add(tf_serverName);
		tf_serverName.setColumns(10);
		
		tf_port = new JTextField();
		tf_port.setColumns(10);
		tf_port.setBounds(189, 262, 96, 21);
		contentPane.add(tf_port);
		
		btn_createServer = new JButton("Create New Server");
		btn_createServer.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				ServerListItem s = new ServerListItem().setServerName(tf_serverName.getText()).setPort(tf_port.getText()).setServer();
				if(s!=null) {
					serverListItems.addElement(s);
					serverList.setModel(serverListItems);
					ta_systemMessage.setText(String.format("%s%s:Create server %s success!\n", ta_systemMessage.getText(),getNow(),s.getServerName()));
				}else {
					JOptionPane.showMessageDialog(null, String.format("You try to craete a new server with port:%s,\nwhich already be used!",tf_port.getText()), String.format("Error! Port can't be same!"), JOptionPane.INFORMATION_MESSAGE);
				}
			}
		});
		btn_createServer.setBounds(116, 300, 153, 23);
		contentPane.add(btn_createServer);
		
		scrollPane = new JScrollPane();
		scrollPane.setBounds(68, 60, 448, 130);
		contentPane.add(scrollPane);
		
		serverList = new JList<ServerListItem>();
		serverList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		serverList.setFont(new Font("Microsoft New Tai Lue", Font.PLAIN, 14));
		scrollPane.setViewportView(serverList);
		
		lblNewLabel = new JLabel("Servers:");
		lblNewLabel.setFont(new Font("新細明體", Font.PLAIN, 17));
		lblNewLabel.setBounds(68, 10, 109, 28);
		contentPane.add(lblNewLabel);
		
		lb_detail = new JLabel(String.format("%-22s %-60s %-20s","Server Name","IP","Enable"));
		lb_detail.setFont(new Font("新細明體", Font.PLAIN, 12));
		lb_detail.setBounds(68, 35, 448, 28);
		contentPane.add(lb_detail);
		
		btn_removeServer = new JButton("Remove Server");
		btn_removeServer.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				final int index = serverList.getSelectedIndex();
				if(index>=0) {
					String name = serverListItems.getElementAt(index).getServerName();
					serverListItems.getElementAt(index).serverTerminate();
					serverListItems.remove(index);
					serverList.setModel(serverListItems);
					ta_systemMessage.setText(String.format("%s%s:Remove server %s success!\n", ta_systemMessage.getText(),getNow(),name));
				}else {
					JOptionPane.showMessageDialog(null, String.format("You should select a server before remove!",tf_port.getText()), String.format("Error! No server was selected!"), JOptionPane.INFORMATION_MESSAGE);
				}
			}
		});
		btn_removeServer.setBounds(116, 330, 153, 23);
		contentPane.add(btn_removeServer);
		
		btn_serverStart = new JButton("Server Start");
		btn_serverStart.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				final int index = serverList.getSelectedIndex();
				if(index>=0) {
					String name = serverListItems.getElementAt(index).getServerName();
					serverListItems.getElementAt(index).start();
					serverList.setModel(serverListItems);
					ta_systemMessage.setText(String.format("%s%s:Start server %s success!\n", ta_systemMessage.getText(),getNow(),name));
				}else {
					JOptionPane.showMessageDialog(null, String.format("You should select a server before start!",tf_port.getText()), String.format("Error! No server was selected!"), JOptionPane.INFORMATION_MESSAGE);
				}
			}
		});
		btn_serverStart.setBounds(116, 360, 153, 23);
		contentPane.add(btn_serverStart);
		
		scrollPane_1 = new JScrollPane();
		scrollPane_1.setBounds(565, 60, 370, 130);
		contentPane.add(scrollPane_1);
		
		ta_systemMessage = new JTextArea();
		ta_systemMessage.setEditable(false);
		scrollPane_1.setViewportView(ta_systemMessage);
		
		lblNewLabel_1 = new JLabel("System Messsage:");
		lblNewLabel_1.setFont(new Font("新細明體", Font.PLAIN, 18));
		lblNewLabel_1.setBounds(565, 15, 134, 32);
		contentPane.add(lblNewLabel_1);
		
		scrollPane_2 = new JScrollPane();
		scrollPane_2.setBounds(344, 260, 591, 130);
		contentPane.add(scrollPane_2);
		
		ta_connectMessage = new JTextArea();
		ta_connectMessage.setEditable(false);
		scrollPane_2.setViewportView(ta_connectMessage);
		
		lblNewLabel_2 = new JLabel("Connect Messsage:");
		lblNewLabel_2.setFont(new Font("新細明體", Font.PLAIN, 18));
		lblNewLabel_2.setBounds(344, 200, 134, 32);
		contentPane.add(lblNewLabel_2);
		
		btn_refresh = new JButton("Refresh connect message");
		btn_refresh.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				while(!connectMessage.isEmpty()) {
					try {
						ta_connectMessage.setText(String.format("%s%s", ta_connectMessage.getText(),connectMessage.take()));
					} catch (InterruptedException e1) {
						e1.printStackTrace();
					}
				}
			}
		});
		btn_refresh.setBounds(741, 200, 194, 23);
		contentPane.add(btn_refresh);
		
		lblNewLabel_3 = new JLabel(String.format("Maximum connect per second:%d",SIZE*(1000/REFERSHTIME) ));
		lblNewLabel_3.setFont(new Font("新細明體", Font.PLAIN, 16));
		lblNewLabel_3.setBounds(344, 229, 258, 21);
		contentPane.add(lblNewLabel_3);
		
		btn_stopCM = new JButton("Stop Connect Message");
		btn_stopCM.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if(HSRServer.connectMessageEnable) {
					HSRServer.connectMessageEnable = false;
					connectMessage.clear();
					btn_stopCM.setText("Start Connect Message");
				}else {
					HSRServer.connectMessageEnable = true;
					connectMessage.clear();
					btn_stopCM.setText("Stop Connect Message");
				}
				
			}
		});
		btn_stopCM.setBounds(741, 227, 194, 23);
		contentPane.add(btn_stopCM);
		autoRefreshConnectMessage();
	}
	public void autoRefreshConnectMessage(){
		new Thread(){
			@Override
			public void run() {
				while(true) {
					while(!connectMessage.isEmpty()) {
						try {
							ta_connectMessage.setText(String.format("%s%s", ta_connectMessage.getText(),connectMessage.take()));
						} catch (InterruptedException e1) {
							e1.printStackTrace();
						}
					}
					try {
						Thread.sleep(REFERSHTIME);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
			}
		}.start();
	}
	public static String getNow() {    
		   DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");  
		   LocalDateTime now = LocalDateTime.now();  
		   return dtf.format(now);  
	}
}
class ServerListItem{
	private String serverName = "Default";
	private int port = 10001;
	public int getPort() {
		return port;
	}
	public String getServerName() {
		return serverName;
	}
	private int timeout = -1;
	private HSRServerWindow hsrsw;
	public ServerListItem(){}
	public ServerListItem setServerName(String serverName) {
		if(!serverName.trim().equals(""))
			this.serverName = serverName;
		return this;
	}
	public ServerListItem setPort(String port) {
		try {
			this.port = Integer.parseInt(port);
		}catch(NumberFormatException e){
			this.port = 10001;
		}
		return this;
	}
	public ServerListItem setTimeout(String timeout) {
		try {
			this.timeout = Integer.parseInt(timeout);
		}catch(NumberFormatException e){
			this.timeout = -1;
		}
		return this;
	}
	public ServerListItem setServer() {
		hsrsw = HSRServerManager.hsrsm.createServer(serverName, port, timeout);
		if(hsrsw == null)
			return null;
		return this;
	}
	
	public void serverTerminate() {
		HSRServerManager.hsrsm.removePort(hsrsw.getPort());
		hsrsw.terminate();
	}
	
	public void start() {
		hsrsw.start();
	}
	@Override
	public String toString() {
		//"Server Name","IP","State"
		return String.format("%-18s %-34s %s",hsrsw.getName(),hsrsw.getIP()+":"+hsrsw.getPort(),Boolean.toString(hsrsw.isAlive()));
	}
}

