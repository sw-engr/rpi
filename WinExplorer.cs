using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.IO;
using System.Windows.Forms;

namespace WinExplorer
{
    // Summary description for WinExplorer form.
	public class WinExplorer : System.Windows.Forms.Form
	{
		private System.Windows.Forms.ToolTip m_toolTip;
		private System.Windows.Forms.ToolBar m_toolBar;
		private System.Windows.Forms.ToolBarButton toolBarButton1;
		private System.Windows.Forms.ToolBarButton toolBarButton2;
		private System.Windows.Forms.ToolBarButton toolBarButton3;
		private System.Windows.Forms.ToolBarButton toolBarButton4;
		private System.Windows.Forms.StatusBar m_statusBar;
		private System.Windows.Forms.ImageList m_imageListToolBar;
		private System.Windows.Forms.TreeView m_tvFolderView;
		private System.Windows.Forms.ListView m_lvFileView;
		private System.Windows.Forms.StatusBarPanel m_statusBarPanel1;
		private System.Windows.Forms.StatusBarPanel m_statusBarPanel2;
		private System.ComponentModel.IContainer components;
		private System.Windows.Forms.ImageList m_imageListTreeView;


        private VScrollBar vScrollBar1;

        private TreeNode m_tnRootNode;
        private TreeNode m_tnDocRootNode;
        private TreeNode m_tnPicRootNode;

        private TreeNodeCollection l_tcDriveCollection;

        private bool[] PopulateFoldersFinished = new bool[3]; //= false;

        // Declare tree path with and without the inclusion of a selected file
        private class PathType
        {
          public string completePath; // complete tree path
          public string pathWithFile; // selected file appended to tree path
        }
        private PathType path = new PathType(); // paths to selected file

        // Declare struct and classes for IgnoreDirectoryTable
        private struct CategoriesType
        {   public int Count;         // number of folders in category
            public int CategoryIndex; // start index in List
            public string Category;   // category name - drive, Documents, Pictures
        }
        private class IgnoreDirectoryTableType 
        {
            public int NumCategories;               // number of lookup categories
            public CategoriesType[] Categories = new CategoriesType[10];
            public int Count;                       // number of files in list
            public string[] List = new string[250]; // files to be ignored
        }

        private static IgnoreDirectoryTableType IgnoreDirectoryTable =
                       new IgnoreDirectoryTableType();

        // the constructor
		public WinExplorer()
		{
			// Required for Windows Form Designer support
			InitializeComponent();

			// Populate the initial Tree View in the left panel
			PopulateTreeView();
		} // end constructor

		// Clean up any resources being used.
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		} // end Dispose

		#region Windows Form Designer generated code

		// Required method for Designer support - do not modify
		// the contents of this method with the code editor.
		private void InitializeComponent()
		{
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(WinExplorer));
            this.m_imageListToolBar = new System.Windows.Forms.ImageList(this.components);
            this.toolBarButton4 = new System.Windows.Forms.ToolBarButton();
            this.m_tvFolderView = new System.Windows.Forms.TreeView();
            this.m_imageListTreeView = new System.Windows.Forms.ImageList(this.components);
            this.toolBarButton1 = new System.Windows.Forms.ToolBarButton();
            this.toolBarButton3 = new System.Windows.Forms.ToolBarButton();
            this.toolBarButton2 = new System.Windows.Forms.ToolBarButton();
            this.m_statusBar = new System.Windows.Forms.StatusBar();
            this.m_statusBarPanel1 = new System.Windows.Forms.StatusBarPanel();
            this.m_statusBarPanel2 = new System.Windows.Forms.StatusBarPanel();
            this.m_toolBar = new System.Windows.Forms.ToolBar();
            this.m_toolTip = new System.Windows.Forms.ToolTip(this.components);
            this.m_lvFileView = new System.Windows.Forms.ListView();
            this.vScrollBar1 = new System.Windows.Forms.VScrollBar();
            ((System.ComponentModel.ISupportInitialize)(this.m_statusBarPanel1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.m_statusBarPanel2)).BeginInit();
            this.SuspendLayout();
            // 
            // m_imageListToolBar
            // 
            this.m_imageListToolBar.ImageStream = ((System.Windows.Forms.ImageListStreamer)(resources.GetObject("m_imageListToolBar.ImageStream")));
            this.m_imageListToolBar.TransparentColor = System.Drawing.Color.Transparent;
            this.m_imageListToolBar.Images.SetKeyName(0, "");
            this.m_imageListToolBar.Images.SetKeyName(1, "");
            this.m_imageListToolBar.Images.SetKeyName(2, "");
            // 
            // toolBarButton4
            // 
            this.toolBarButton4.ImageIndex = 2;
            this.toolBarButton4.Name = "toolBarButton4";
            this.toolBarButton4.ToolTipText = "Close this application";
            // 
            // m_tvFolderView
            // 
            this.m_tvFolderView.ImageIndex = 0;
            this.m_tvFolderView.ImageList = this.m_imageListTreeView;
            this.m_tvFolderView.Location = new System.Drawing.Point(5, 35);
            this.m_tvFolderView.Name = "m_tvFolderView";
            this.m_tvFolderView.SelectedImageIndex = 0;
            this.m_tvFolderView.Size = new System.Drawing.Size(343, 535);
            this.m_tvFolderView.TabIndex = 0;
            this.m_toolTip.SetToolTip(this.m_tvFolderView, "Displays drives and folders in your machine");
            this.m_tvFolderView.NodeMouseClick += new System.Windows.Forms.TreeNodeMouseClickEventHandler(this.m_tvFolderView_NodeMouseClick);
            // 
            // m_imageListTreeView
            // 
            this.m_imageListTreeView.ImageStream = ((System.Windows.Forms.ImageListStreamer)(resources.GetObject("m_imageListTreeView.ImageStream")));
            this.m_imageListTreeView.TransparentColor = System.Drawing.Color.Transparent;
            this.m_imageListTreeView.Images.SetKeyName(0, "");
            this.m_imageListTreeView.Images.SetKeyName(1, "");
            this.m_imageListTreeView.Images.SetKeyName(2, "");
            this.m_imageListTreeView.Images.SetKeyName(3, "");
            this.m_imageListTreeView.Images.SetKeyName(4, "");
            this.m_imageListTreeView.Images.SetKeyName(5, "My_Documents_image.png");
            // 
            // toolBarButton1
            // 
            this.toolBarButton1.ImageIndex = 0;
            this.toolBarButton1.Name = "toolBarButton1";
            this.toolBarButton1.ToolTipText = "Click to Refresh drives and folders";
            // 
            // toolBarButton3
            // 
            this.toolBarButton3.Name = "toolBarButton3";
            this.toolBarButton3.Style = System.Windows.Forms.ToolBarButtonStyle.Separator;
            this.toolBarButton3.Text = "toolBarButton3";
            // 
            // toolBarButton2
            // 
            this.toolBarButton2.ImageIndex = 1;
            this.toolBarButton2.Name = "toolBarButton2";
            this.toolBarButton2.ToolTipText = "Displays version information";
            // 
            // m_statusBar
            // 
            this.m_statusBar.Location = new System.Drawing.Point(0, 642);
            this.m_statusBar.Name = "m_statusBar";
            this.m_statusBar.Panels.AddRange(new System.Windows.Forms.StatusBarPanel[] {
            this.m_statusBarPanel1,
            this.m_statusBarPanel2});
            this.m_statusBar.ShowPanels = true;
            this.m_statusBar.Size = new System.Drawing.Size(844, 23);
            this.m_statusBar.SizingGrip = false;
            this.m_statusBar.TabIndex = 3;
            // 
            // m_statusBarPanel1
            // 
            this.m_statusBarPanel1.Name = "m_statusBarPanel1";
            this.m_statusBarPanel1.Text = "Folders";
            this.m_statusBarPanel1.Width = 294;
            // 
            // m_statusBarPanel2
            // 
            this.m_statusBarPanel2.Name = "m_statusBarPanel2";
            this.m_statusBarPanel2.Text = "Files";
            this.m_statusBarPanel2.Width = 450;
            // 
            // m_toolBar
            // 
            this.m_toolBar.Buttons.AddRange(new System.Windows.Forms.ToolBarButton[] {
            this.toolBarButton1,
            this.toolBarButton2,
            this.toolBarButton3,
            this.toolBarButton4});
            this.m_toolBar.DropDownArrows = true;
            this.m_toolBar.ImageList = this.m_imageListToolBar;
            this.m_toolBar.Location = new System.Drawing.Point(0, 0);
            this.m_toolBar.Name = "m_toolBar";
            this.m_toolBar.ShowToolTips = true;
            this.m_toolBar.Size = new System.Drawing.Size(844, 28);
            this.m_toolBar.TabIndex = 2;
            this.m_toolBar.ButtonClick += new System.Windows.Forms.ToolBarButtonClickEventHandler(this.OnButtonClickToolBar);
            // 
            // m_lvFileView
            // 
            this.m_lvFileView.Location = new System.Drawing.Point(353, 35);
            this.m_lvFileView.MultiSelect = false;
            this.m_lvFileView.Name = "m_lvFileView";
            this.m_lvFileView.Size = new System.Drawing.Size(541, 535);
            this.m_lvFileView.TabIndex = 1;
            this.m_toolTip.SetToolTip(this.m_lvFileView, "Displays files in your machine");
            this.m_lvFileView.UseCompatibleStateImageBehavior = false;
            this.m_lvFileView.View = System.Windows.Forms.View.Details;
            this.m_lvFileView.SelectedIndexChanged += new System.EventHandler(this.m_lvFileView_SelectedIndexChanged);
            // 
            // vScrollBar1
            // 
            this.vScrollBar1.Location = new System.Drawing.Point(299, 31);
            this.vScrollBar1.Name = "vScrollBar1";
            this.vScrollBar1.Size = new System.Drawing.Size(21, 535);
            this.vScrollBar1.TabIndex = 4;
            this.vScrollBar1.Visible = false;
            // 
            // WinExplorer
            // 
            this.AutoScaleBaseSize = new System.Drawing.Size(6, 15);
            this.ClientSize = new System.Drawing.Size(844, 665);
            this.Controls.Add(this.vScrollBar1);
            this.Controls.Add(this.m_statusBar);
            this.Controls.Add(this.m_toolBar);
            this.Controls.Add(this.m_lvFileView);
            this.Controls.Add(this.m_tvFolderView);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "WinExplorer";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Windows Explorer in C# -- Click Node to Populate";
            ((System.ComponentModel.ISupportInitialize)(this.m_statusBarPanel1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.m_statusBarPanel2)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

		} // end InitializeComponent
		#endregion

		// The main entry point for the application.
		[STAThread]
		static void Main() 
		{
            // Add the ability to save console output in a forms app
            ConsoleOut.Install("C:\\Source\\C#\\FileXferWinExplorer\\ConsoleOut.txt"); 

            // Open the IgnoreDirectory.dat file and build the table
            FindDirectoriesToIgnore();

            // Start the WinExplorer form
			Application.Run(new WinExplorer());
		} // end Main

        private static void FindDirectoriesToIgnore()
        {
            IgnoreDirectoryTable.NumCategories = 0;

            // Obtain the path of the file.
            string toIgnoreFile = FindFile("IgnoreDirectory.dat");

            if (toIgnoreFile.Length < 8)
            {
                ConsoleOut.WriteLine("ERROR: No IgnoreDirectory.dat file found");
                return;
            }

            // Get Logical Drives on this machine
            DriveInfo[] allDrives = DriveInfo.GetDrives();

            int i = 0;
            foreach (DriveInfo d in allDrives)
            {
                string l_strCurrDrive = d.Name;

                // Add categories to the IgnoreDirectoryTable to use when searching it.
                // First add the available drives
                {
                    IgnoreDirectoryTable.Categories[i].Category = l_strCurrDrive;
                    IgnoreDirectoryTable.Categories[i].Count = 0;
                    IgnoreDirectoryTable.Categories[i].CategoryIndex = 0;
                    IgnoreDirectoryTable.NumCategories++;
                }
                i++;
            } // foreach drive

            // Lastly add the special categories
            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].Category = "DOC";
            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].Count = 0;
            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].CategoryIndex = 0;
            int IndexDoc = IgnoreDirectoryTable.NumCategories;
            IgnoreDirectoryTable.NumCategories++;

            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].Category = "PIC";
            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].Count = 0;
            IgnoreDirectoryTable.Categories[IgnoreDirectoryTable.NumCategories].CategoryIndex = 0;
            int IndexPic = IgnoreDirectoryTable.NumCategories;
            IgnoreDirectoryTable.NumCategories++;

            string line;
            int linesAdded = 0;

            // Open the file and read and transfer its files names to the table
            System.IO.StreamReader file =
                                   new System.IO.StreamReader(toIgnoreFile);
            while ((line = file.ReadLine()) != null)
            {
                string catName = "";
                string uLine = line.ToUpper();
                IgnoreDirectoryTable.List[IgnoreDirectoryTable.Count] = uLine;
                IgnoreDirectoryTable.Count++; // total number of entries
                // Put the file into its category
                int temp1 = uLine.IndexOf("\\");
                if ((temp1 == -1) || (uLine.Length < 21)) // not the Users folder
                {
                    catName = uLine.Substring(0, 3);
                    for (int c = 0; c < IgnoreDirectoryTable.NumCategories; c++)
                    {
                        if (catName == IgnoreDirectoryTable.Categories[c].Category)
                        {
                            if (IgnoreDirectoryTable.Categories[c].Count == 0)
                            {
                                IgnoreDirectoryTable.Categories[c].CategoryIndex = linesAdded;
                            }
                            IgnoreDirectoryTable.Categories[c].Count++;
                            linesAdded++;
                            break; // exit loop
                        }
                    }
                }
                else
                {
                    int temp2 = uLine.IndexOf("USERS\\", temp1 + 1, 6);
                    if (temp2 == -1) // not the Users folder
                    {
                        catName = uLine.Substring(0, 3);
                        for (int c = 0; c < IgnoreDirectoryTable.NumCategories; c++)
                        {
                            if (catName == IgnoreDirectoryTable.Categories[c].Category)
                            {
                                if (IgnoreDirectoryTable.Categories[c].Count == 0)
                                {
                                    IgnoreDirectoryTable.Categories[c].CategoryIndex = linesAdded;
                                }
                                IgnoreDirectoryTable.Categories[c].Count++;
                                linesAdded++;
                                break; // exit loop
                            }
                        }
                    }
                    else
                    {
                        // Determine if My Documents or My Pictures path
                        // start index at temp1+6 to find next \
                        int temp3 = uLine.IndexOf("DOCUMENTS\\");
                        if (temp3 != -1)
                        {
                            // path follows 10th character
                            string path = uLine.Substring(temp3 + 10);
                            if (IgnoreDirectoryTable.Categories[IndexDoc].Count == 0)
                            { // set where to being looking 
                                IgnoreDirectoryTable.Categories[IndexDoc].CategoryIndex =
                                    IgnoreDirectoryTable.Count - 1;
                            }
                            IgnoreDirectoryTable.Categories[IndexDoc].Count++;
                        }
                        else
                        {
                            temp3 = uLine.IndexOf("PICTURES\\");
                            if (temp3 != -1)
                            {
                                // path follows 9th character
                                string path = uLine.Substring(temp3 + 9);
                                if (IgnoreDirectoryTable.Categories[IndexPic].Count == 0)
                                { // set where to being looking 
                                    IgnoreDirectoryTable.Categories[IndexPic].CategoryIndex =
                                        IgnoreDirectoryTable.Count - 1;
                                }
                                IgnoreDirectoryTable.Categories[IndexPic].Count++;
                            }
                        }
                    }
                }

            }
            file.Close();
 
        } // end FindDirectoriesToIgnore

        // Locate the specified file in the path of application execution
        static private string FindFile(string file)
        {
            string nullFile = "";

            // Get the current directory/folder
            string path = Directory.GetCurrentDirectory();

            // Find the .dat file in the path
            bool notFound = true;
            while (notFound)
            {
                // Look for the file in this directory
                string newPath;
                char backSlash = '\\';
                int index = path.Length - 1;
                for (int i = 0; i < path.Length; i++)
                {
                    int equal = path[index].CompareTo(backSlash);
                    if (equal == 0)
                    {
                        newPath = path.Substring(0, index); // the portion of path that
                                                            //  ends just before '\'
                        string[] dirs = Directory.GetFiles(newPath, "*.dat");
                        int fileLength = file.Length;
                        foreach (string dir in dirs)
                        {
                            string datFile = dir.Substring(index + 1, fileLength);
                            equal = datFile.CompareTo(file);
                            if (equal == 0)
                            {
                                return dir;
                            }
                        }
                        path = newPath; // reduce path to look again
                        if (path.Length < 10)
                        { return nullFile; }
                    } // end equal == 0
                    index--;

                } // end for loop
            } // end while loop

            return nullFile;

        } // end FindFile

        // Return FullPath without prefixes that aren't part of the path
        private string CompletePath(TreeNode currNode)
        {
            string l_strCurPath = currNode.FullPath;

            ConsoleOut.WriteLine("CompletePath " + l_strCurPath);

            // Remove "My Computer", "My Documents", and "My Pictures" from the path
            int len = l_strCurPath.Length;
            if (len > 12)
            {
                int temp = l_strCurPath.IndexOf("\\");
                if (temp == 11)
                {
                    l_strCurPath = l_strCurPath.Remove(0, 12);
                }
                else if (temp == 12)
                {
                    l_strCurPath = l_strCurPath.Remove(0, 13);
                }
                else if (temp == 13) {
                    l_strCurPath = l_strCurPath.Remove(0, 14);
                }
            }

            // Adjust to remove extra \ following drive
            for (int i = 0; i < l_strCurPath.Length - 1; i++)
            {
                if ((l_strCurPath[i] == '\\') && (l_strCurPath[i + 1] == '\\'))
                {
                    l_strCurPath = l_strCurPath.Remove(i + 1, 1); // remove extra \
                    break; // exit loop
                }
                else if (l_strCurPath[i] == '\\')
                {
                    break; // no need to look past the \ of the drive
                }
            }
            path.completePath = l_strCurPath;
            return l_strCurPath;

        } // end CompletePath

        // Get all directories of the current tree node
        private string[] GetDirectories(string CurrPath)
        {
            string[] strArrDirs;
            try
            {
                strArrDirs = Directory.GetDirectories(CurrPath);
                ConsoleOut.WriteLine("GetDirectories normal return " + CurrPath);
                return strArrDirs;
            }
            catch
            {
                strArrDirs = new string[] { "" };
                ConsoleOut.WriteLine("GetDirectories error return " + CurrPath);
                return strArrDirs;
            }

        } // end GetDirectories

        // Get all files of the current tree node
        private string[] GetFiles(string CurrPath)
        {
            string[] strArrFiles;
            try
            {
                strArrFiles = Directory.GetFiles(CurrPath);
                ConsoleOut.WriteLine("GetFiles normal return " + CurrPath);
                return strArrFiles;
            }
            catch
            {
                strArrFiles = new string[] { "" };
                ConsoleOut.WriteLine("GetFiles error return " + CurrPath);
                return strArrFiles;
            }

        } // end GetFiles

        protected void RefreshFolders(){
            ConsoleOut.WriteLine("RefreshFolders");
			m_lvFileView.Clear(); // clear the FileView
			PopulateTreeView();   // repopulate the tree view 
			m_tvFolderView.Parent.Select();
		} // end RefreshFolders

    	// Previously this method added all drives in the Tree view and invoked
        // the PopulateFolders method to add folders for each drive which 
        // recursively invokes itself.  It also added the Documents and Pictures
        // folders of the C:\Users\SpecialFolder\MyDocuments and MyPictures of
        // the Environment.
        //
        // This can take quite a long time preventing the form from being 
        // displayed.  This can be significantly speeded up by supplying an 
        // IgnoreDirectory.dat file containing the paths of directories to be
        // ignored.  Paths to files to be displayed in the List View can also
        // be included if the user doesn't wish for the file to be visible.
        //
        // Now the PopulateTreeViewFolders method has been added to do one
        // root node at a time depending upon the selection that the users
        // makes after the minimal form has been displayed with only the
        // root nodes showing.  PopulateTreeViewFolders then takes the place
        // of this method in preparing to invoke the PopulateFolders method 
        // until all non-hidden folders for which there is privilege to 
        // access and for which the user has not specified that the folder is 
        // to be ignored.  Such folders and files can be supplied in the 
        // IgnoreDirectory.dat file placed in the path back from the .exe file.
        //
        // Also, there are ConsoleOut.WriteLine statements that write to a
        // ConsoleOut.txt file specified by the Main entry point.  Any user
        // with access to the code can change this location as desired and
        // can add to or delete WriteLine statements to help track what is
        // happening when not stepping via the debugger.  ConsoleOut is 
        // meant as a replacement for Console which isn't available for a
        // Windows Forms application such as this.
        protected int PopulateTreeView() {
            this.Cursor = Cursors.WaitCursor;
            
            m_tvFolderView.Nodes.Clear(); // clear the left panel

            PopulateFoldersFinished[0] = false; // indicate that the
            PopulateFoldersFinished[1] = false; //   root nodes have yet
            PopulateFoldersFinished[2] = false; //   to be populated

            m_tnRootNode = new TreeNode("My Computer", 0, 0);
            m_tvFolderView.Nodes.Add(m_tnRootNode);

            m_tnDocRootNode = new TreeNode("My Documents", 5, 5);
            m_tvFolderView.Nodes.Add(m_tnDocRootNode);

            m_tnPicRootNode = new TreeNode("My Pictures", 5, 5);
            m_tvFolderView.Nodes.Add(m_tnPicRootNode);

            l_tcDriveCollection = m_tnRootNode.Nodes;

            InitListControl();

            this.Cursor = Cursors.Arrow;
            return 1;

		} // end PopulateTreeView

        // Populate the tree for a root node as selected by the user.  
        // This is an extension of PopulateTreeView where the code, somewhat
        // modified, used to be part of PopulateTreeView when the all the
        // folders of all the root nodes were populated at once.
	    protected int PopulateTreeViewFolders(TreeNode RootNode) {

            if (RootNode == m_tnRootNode) {
 
                // Get Logical Drives on this machine
                string[] l_arrAvailableDrives = Environment.GetLogicalDrives();
                string l_strCurrDrive = "";

                foreach (object obj in l_arrAvailableDrives)
                {
                    l_strCurrDrive = (string)obj;
                    ConsoleOut.WriteLine("PopulateTreeView " + l_strCurrDrive);

                    // Add the Node
                    bool driveExists = true;
                    try
                    {
                        if (Directory.Exists(l_strCurrDrive) == false)
                        {
                            driveExists = false;
                        }
                    }
                    catch { }

                    if (driveExists)
                    {
                        int l_iImageIndex = 0, l_iSelectedIndex = 0;
                        if (l_strCurrDrive.Equals("A:\\"))
                        {
                            // For A:\ drive
                            l_iImageIndex = 1;
                            l_iSelectedIndex = 1;
                        }
                        else
                        {
                            l_iImageIndex = 4; // 2;
                            l_iSelectedIndex = 2; // 3;
                        } 
                        
                        // Create the Drive Root node
                        TreeNode l_tnDriveNode = new TreeNode(l_strCurrDrive, 
                                                              l_iImageIndex, 
                                                              l_iSelectedIndex);
                        l_tcDriveCollection.Add(l_tnDriveNode);
                        TreeNodeCollection l_tcFileCollection = l_tnDriveNode.Nodes;
                        PopulateFolders(l_strCurrDrive, l_tcFileCollection);

                    } // end if (driveExists)
                } // end loop

                PopulateFoldersFinished[0] = true;
            } // end RootNode == m_tnRootNode 

            else if (RootNode == m_tnDocRootNode) {
                TreeNodeCollection l_tcDocCollection = m_tnDocRootNode.Nodes;
                string l_strDocuments =
                    Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
                TreeNode em_tnDocNode = new TreeNode(l_strDocuments, 4, 2);
                l_tcDocCollection.Add(em_tnDocNode);
                TreeNodeCollection l_tcDocFileCollection = em_tnDocNode.Nodes;
                PopulateFolders(l_strDocuments, l_tcDocFileCollection);
                PopulateFoldersFinished[1] = true;
            } // end if RootNode == m_tnDocRootNode

            else { 
                // repeat the above for m_tnPicRootNode.Nodes.
                TreeNodeCollection l_tcPicCollection = m_tnPicRootNode.Nodes;
                string l_strPictures =
                    Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
                TreeNode em_tnPicNode = new TreeNode(l_strPictures, 4, 2);
                l_tcPicCollection.Add(em_tnPicNode);
                TreeNodeCollection l_tcPicFileCollection = em_tnPicNode.Nodes;
                PopulateFolders(l_strPictures, l_tcPicFileCollection);
                PopulateFoldersFinished[2] = true;
            } // end RootNode == m_tnPicRootNode

            InitListControl();

            this.Cursor = Cursors.Arrow;

            return 1;

		} // end PopulateTreeViewFolders

		//	Get sub directories of a current drive or directory without recursion
		protected int PopulateFolders(string l_strCurrDir,
                                      TreeNodeCollection l_tcCollection) {

            ConsoleOut.WriteLine("PopulateFolders " + l_strCurrDir);
			try {
			
				string[] l_childDirs = GetDirectories(l_strCurrDir);
				string l_strDirFullPath = "" ,l_strDirName = "";

				int l_iImageIndex = 0, l_iSelectedImage = 0;
                foreach (string l_strTempDirName in l_childDirs)
                {
                    if (l_strTempDirName != "")
                    {
                        l_strDirFullPath = l_strTempDirName;

                        // Get the directory name from the path
                        l_strDirName = Path.GetFileName(l_strDirFullPath);
 
                        ConsoleOut.WriteLine("PopulateFolders directory " + l_strDirName);

                        // Check if to ignore directories via the IgnoreDirectoryTable
                        string u_strTemp = l_strDirFullPath.ToUpper();
                        if (!IgnoreFolderOrFile(u_strTemp, "Folder")) {
 
                            // Populate the TreeView with the Directory unless Hidden 
                            bool ChildFolders = CheckIfChildFolders(l_strDirFullPath);
                            ConsoleOut.WriteLine("ChildFolders " + ChildFolders);

                            var fInfo = new FileInfo(l_strDirFullPath);
                            if (!fInfo.Attributes.HasFlag(FileAttributes.Hidden))
                            {
                                u_strTemp = l_strDirName.ToUpper();
                                if (u_strTemp.Equals("RECYCLED") || 
                                    u_strTemp.Equals("RECYCLER") ||
                                    u_strTemp.Equals("$RECYCLE.BIN"))
                                {
                                    l_iImageIndex = 3; // 4[
                                    l_iSelectedImage = 3; // 4;
                                }
                                else
                                {
                                    l_iImageIndex = 4; // 2;
                                    l_iSelectedImage = 2; // 3;
                                }

                                TreeNode l_curNode = new TreeNode(l_strDirName, 
                                                                  l_iImageIndex,
                                                                  l_iSelectedImage);
                                l_tcCollection.Add(l_curNode);
                                ConsoleOut.WriteLine("PopulateFolders l_curNode.IsSelected= "
                                                     + l_curNode.ToString() + " " + 
                                                     l_curNode.IsSelected);

                                if (ChildFolders)
                                {
                                    string l_strChildDir = l_strDirFullPath + @"\";
                                    PopulateFolders(l_strChildDir, l_curNode.Nodes);
                                }

                            } // end not hidden
                        } // end not ignore
                        
                    } // end l_strTempDirName != ""
                } // end foreach loop
            } // end try
		 	catch{
			 	// If there is any other runtime error while accessing folders,
				// then catch the error and do nothing
			    return 0;
			}

		    return 1;
		} // end PopulateFolders

        // Return true if current directory has any child directories
        bool CheckIfChildFolders(string l_strCurrDir)
        {
            string[] l_childDirs = GetDirectories(l_strCurrDir);
            if (l_childDirs.Length > 0) 
            {
                foreach (string l_strTempDirName in l_childDirs)
                {
                    if (l_strTempDirName != "")
                        return true;
                    else return false;
                }
            }
            return false;

        } // end CheckIfChildFolders

        bool IgnoreFolderOrFile(string u_strTemp, string classification)
        {
            // Ignore directories in IgnoreDirectoryTable
            string catName = "";
            int stopCount = 0;
            int i = 0;

            int temp1 = u_strTemp.IndexOf("\\");
            if ((temp1 == -1) || (u_strTemp.Length < 21)) // not the Users folder
            {
                catName = u_strTemp.Substring(0, 3);
            }
            else
            {
                int temp2 = u_strTemp.IndexOf("USERS\\", temp1 + 1, 6);
                if (temp2 == -1) // no USERS\ in path
                {
                    catName = u_strTemp.Substring(0, 3);
                }
                else
                {
                    // Determine if My Documents or My Pictures path
                    // start index at temp1+6 to find next \
                    int temp3 = u_strTemp.IndexOf("DOCUMENTS\\");
                    if (temp3 != -1)
                    {
                        catName = "DOC";
                    }
                    else
                    {
                        temp3 = u_strTemp.IndexOf("PICTURES\\");
                        if (temp3 != -1)
                        {
                            catName = "PIC";
                        }
                    }
                }
            }

            bool ignore = false;
            int c = 0;
            while (c < IgnoreDirectoryTable.NumCategories)
            {
                if (IgnoreDirectoryTable.Categories[c].Category == catName)
                {
                    if (IgnoreDirectoryTable.Categories[c].Count == 0)
                    {
                        break; // exit loop, no entries to ignore
                    }
                    else
                    {
                        // initial index for category
                        i = IgnoreDirectoryTable.Categories[c].CategoryIndex;
                        stopCount = IgnoreDirectoryTable.Categories[c].Count;
                        break; // exit loop with search boundaries
                    }
                }
                c++;
            } // end while

            // Search that portion of the Ignore table that 
            // corresponds to the range of the category of the path.
            int count = 0;
            while ((i < IgnoreDirectoryTable.Count) &&
                   (count < stopCount))
            {
                string tabFile = IgnoreDirectoryTable.List[i];
                if (IgnoreDirectoryTable.List[i] == u_strTemp)
                {
                    ignore = true;
                    break; // exit loop
                }
                i++;
                count++;
            } // end while

            return ignore;

        } // end IgnoreFolderOrFile

        // Populate List view control with files
        protected void PopulateListView(TreeNode l_tnCurrNode)
        {
            this.Cursor = Cursors.WaitCursor; 

            // Clear all items from list control
			InitListControl();

			// Remove "My Computer", "My Documents", "My Pictures" from the path
            string l_strCurPath = CompletePath(l_tnCurrNode);

            // Ignore if "My Documents" or "My Pictures" since these have no files
            if ((l_strCurPath == "My Documents") || (l_strCurPath == "My Pictures"))
            {
                return;
            }

			m_statusBarPanel1.Text = "Refreshing files " + l_strCurPath +
                                     ". Please wait...";

			try {

				if ( Directory.Exists(l_strCurPath) == false ) {
					this.Cursor = Cursors.Arrow;
					string l_strError1 = "Directory or Path " + l_strCurPath[0] +
                                         " doesn't exist";
					MessageBox.Show(l_strError1,"Windows Explorer - Error",
                                    MessageBoxButtons.OK,MessageBoxIcon.Stop);
					m_tvFolderView.Parent.Focus();
					m_statusBarPanel1.Text = "Error in accessing " + l_strCurPath;
					m_statusBarPanel2.Text = "";
					return;
				}

                string[] l_strarrFiles = GetFiles(l_strCurPath); //actualPath);
                int l_iCount = 0;
				string l_strFileName = "";
				string[] l_strSubItems = new string[4];
				DateTime l_dtCreationTime,l_dtModifiedTime;
				long l_lFileSize = 0;
				foreach (string l_strFile in l_strarrFiles) {
					
					l_strFileName = l_strFile;

                    var fInfo = new FileInfo(l_strFile); //l_strCurPath); //l_strFileName);
                    if (! fInfo.Attributes.HasFlag(FileAttributes.Hidden))
                    {
                        string u_strFile = l_strFileName.ToUpper();
                        if (!IgnoreFolderOrFile(u_strFile, "File")) {

					        if ( ! u_strFile.Equals("PAGEFILE.SYS") ) {
                                l_lFileSize = fInfo.Length;
						        l_dtCreationTime = File.GetCreationTime(l_strFile);
						        l_dtModifiedTime = File.GetLastAccessTime(l_strFile);
						        l_strFileName = Path.GetFileName(l_strFileName);
 
						        l_strSubItems[0] = l_strFileName;
						        l_strSubItems[1] = ConvertFileLenToKB(l_lFileSize);
						        l_strSubItems[2] = l_dtCreationTime.Day.ToString() + 
                                                   "/" + l_dtCreationTime.Month.ToString()
                                                   + "/" + l_dtCreationTime.Year.ToString()
                                                   + " " + l_dtCreationTime.Hour.ToString()
                                                   + ":" + l_dtCreationTime.Minute.ToString()
                                                   + ":" + l_dtCreationTime.Second.ToString();
						        l_strSubItems[3] = l_dtModifiedTime.Day.ToString() + "/" + 
                                                   l_dtModifiedTime.Month.ToString() + "/" + 
                                                   l_dtModifiedTime.Year.ToString() + " " + 
                                                   l_dtModifiedTime.Hour.ToString() + ":" + 
                                                   l_dtModifiedTime.Minute.ToString() + ":" + 
                                                   l_dtModifiedTime.Second.ToString();
					        }
					        else {
						        l_strSubItems[0] = "unknown";
						        l_strSubItems[1] = "unknown";
					 	        l_strSubItems[2] = "unknown";
						        l_strSubItems[3] = "unknown";
					        }
					
					        ListViewItem l_lviItem = new ListViewItem(l_strSubItems,0);

					        m_lvFileView.Items.Add(l_lviItem);
				 	        l_iCount++;
                        } // end if not Ignore
                    } // end if !hidden

                } // end foreach
				
				m_statusBarPanel1.Text = l_strCurPath;
				m_statusBarPanel2.Text = "File(s) :  " + l_iCount.ToString();

				this.Cursor = Cursors.Arrow;
			}
			catch ( IOException e ) {
                this.Cursor = Cursors.Arrow;
                string l_strError = "Error Occured while accessing directory " + l_strCurPath;
                l_strError += "\nError Message :" + e;
                MessageBox.Show(l_strError, "Windows Explorer - Error", 
                                MessageBoxButtons.OK, MessageBoxIcon.Stop);
                m_tvFolderView.Parent.Focus();
                m_statusBarPanel1.Text = "Error in accessing " + l_strCurPath;
                m_statusBarPanel2.Text = "";
                return;
			}
			return;
 
		} // end PopulateListView

		// This function takes file length and returns the kilobyte length in
		// string format appended with KB
		protected string ConvertFileLenToKB(long ll_FileSize){
			string l_strFileSize = "";
			int l_iOneKB = 1024,l_iCount = 0;
			for ( ; ll_FileSize > l_iOneKB ; ll_FileSize -= l_iOneKB,l_iCount++ ) ;
			
			if ( l_iCount > 0 ) {
                l_iCount++;
				l_strFileSize = l_iCount.ToString();
			}
			else {
				l_strFileSize = ll_FileSize.ToString();
			}

            l_strFileSize = FormatString(l_strFileSize);

			// Append KB to it
			if ( l_iCount > 0 ) {
				l_strFileSize += " KB";
			}
			
			return l_strFileSize;
		} // end ConvertFileLenToKB

		//	This function takes a number as string and formats 
		//	it with commas at every 3 digits
		protected string FormatString(string l_strInput)
        {
			int l_iLen = 0,l_iCount = 0,l_iCount1 = 1 ;
			string l_strOutput = "";

			l_strInput.Trim();
			l_iLen = l_strInput.Length;
			for ( l_iLen-- ; l_iLen >= 0 ; l_iLen--,l_iCount++,l_iCount1++ ) {
				l_strOutput += l_strInput[l_iLen];
				if ( l_iCount1 % 3 == 0 && ( l_strInput.Length % 3 != 0 )) {
					l_iCount++;
					l_strOutput += ',';
				}
			} // end for
			string l_strTemp = "";
			// Reverse the string here
			l_iLen = l_strOutput.Length;
			l_iLen--;
			for ( l_iCount = l_iLen ; l_iCount >= 0 ; l_iCount-- ) {
				l_strTemp += l_strOutput[l_iCount];
			}
			return l_strTemp;
		} // end FormatString 

		// Initialise FileView List control
		protected void InitListControl() {
			m_lvFileView.Clear();
			m_lvFileView.Columns.Add("Name",225,HorizontalAlignment.Left );
			m_lvFileView.Columns.Add("Size",70,HorizontalAlignment.Right );
			m_lvFileView.Columns.Add("Created",105,HorizontalAlignment.Left );
			m_lvFileView.Columns.Add("Modified",105,HorizontalAlignment.Left );
		} // end InitListControl

        // Add the file name to the complete tree path
        private string AddFileToPath(string selectedFile)
        {
            string tempPath = path.completePath;
            tempPath += "\\";
            tempPath += selectedFile;
            path.pathWithFile = tempPath;
            return tempPath;
        } // end AddFileToPath

        /***********************************************************************
         *                       Event Handlers                                *
         ***********************************************************************
         */
        private void OnButtonClickToolBar(object sender, 
                             System.Windows.Forms.ToolBarButtonClickEventArgs e)
        {
            int l_iImageIndex = e.Button.ImageIndex;
            if (l_iImageIndex == 0)
            {
                RefreshFolders();
            }
            else if (l_iImageIndex == 1)
            {
                AboutDlg dlg = new AboutDlg();
                dlg.ShowDialog(this);
            }
            else if (l_iImageIndex == 2)
            {
                this.Close();
            }
        } // end OnButtonClickToolBar event handler

        private void m_tvFolderView_NodeMouseClick(object sender, 
                                                   TreeNodeMouseClickEventArgs e)
        {
            // Find the node specified by the user.
            TreeNode l_tnCurrNode = e.Node;
            /*	If selected node is "My Computer", "My Documents", or "My 
             *  Pictures" (Root nodes) then no need to populate List View
             *  control, clear the List View control and create the header 
             */
            if (m_tnRootNode == l_tnCurrNode)
            {
                if (PopulateFoldersFinished[0])
                {
                    InitListControl();
                    m_statusBarPanel1.Text = "My Computer";
                    m_statusBarPanel2.Text = "";
                }
                else
                {
                    m_statusBarPanel1.Text = "My Computer";
                    m_statusBarPanel2.Text = "Refreshing Folders and Files. Please wait...";
                    PopulateTreeViewFolders(l_tnCurrNode);
                    m_statusBarPanel2.Text = "";
                    this.Text = "Windows Explorer in C#";
                }
                return;
            } 
            else if (m_tnDocRootNode == l_tnCurrNode)
            {
                if (PopulateFoldersFinished[1])
                {
                    InitListControl();
                    m_statusBarPanel1.Text = "My Documents";
                }
                else
                {
                    m_statusBarPanel1.Text = "My Documents";
                    m_statusBarPanel2.Text = "Refreshing Folders and Files. Please wait...";
                    PopulateTreeViewFolders(l_tnCurrNode);
                    m_statusBarPanel2.Text = "";
                    this.Text = "Windows Explorer in C#";
                }
                return;
            }
            else if (m_tnPicRootNode == l_tnCurrNode)
            {
                if (PopulateFoldersFinished[2])
                {
                    InitListControl();
                    m_statusBarPanel1.Text = "My Pictures";
                }
                else
                {
                    m_statusBarPanel1.Text = "My Pictures";
                    m_statusBarPanel2.Text = "Refreshing Folders and Files. Please wait...";
                    PopulateTreeViewFolders(l_tnCurrNode);
                    m_statusBarPanel2.Text = "";
                    this.Text = "Windows Explorer in C#";
                }
                return;
            } 

            if (l_tnCurrNode.Text == "A:\\")
            {
                //	Clear all sub items before proceding 
                this.Cursor = Cursors.WaitCursor;
                e.Node.Nodes.Clear();
                InitListControl();
                TreeNodeCollection l_tcFileCollection = e.Node.Nodes;
                int l_iRetval = PopulateFolders("A:\\", l_tcFileCollection);
                this.Cursor = Cursors.Arrow;
                if (l_iRetval == 0)
                {
                    //	If directory doesn't exist then don't call PopulateListView() 
                    return;
                }
            }
            
 	        this.Cursor = Cursors.WaitCursor;
			PopulateListView(l_tnCurrNode);
			this.Cursor = Cursors.Arrow;
        } // end m_tvFolderView_NodeMouseClick 

        // To be used to select the path to a file
        private void m_lvFileView_SelectedIndexChanged(object sender, EventArgs e)
        {
            var selectedItems = m_lvFileView.SelectedItems;
            foreach (ListViewItem selectedItem in selectedItems)
            {
                string pathWithFile = AddFileToPath(selectedItem.Text);
            }

        } // end m_lvFileView_SelectedIndexChanged
	
	} // end class

} // end namespace
