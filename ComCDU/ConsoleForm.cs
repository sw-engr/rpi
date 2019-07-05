using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace VisualCompiler
{

    public partial class ConsoleForm : Form
    {
   //     static private System.Windows.Forms.ListBox consoleText = ConsoleText;
        static public ConsoleForm consoleForm = new ConsoleForm();
  //      ConsoleForm consoleForm = new ConsoleForm();

        public ConsoleForm()
        {
            InitializeComponent();
            consoleForm.Visible = true;
        } // end constructor

        // Add text to the ConsoleText listbox and to a file to be retained
        // after session finished.  This is to replace ConsoleForm since not
        // usable when have Windows forms.
  //      static public void ConsoleOut(String text)
  //      {
  //          this.ConsoleText.Items.Add(text);

  //      } // end ConsoleForm

        static public void WriteLine(String text)
        {
            consoleForm.ConsoleText.Items.Add(text);
     //       writeLine(text);
        } // end WriteLine

        static public void Write(String text)
        {
            consoleForm.ConsoleText.Items.Add(text);
            // these need indicate if the first Write of the line and keep appending text
            // until the WriteLine is encountered
        } // end Write

 //       public void writeLine(String text)
 //       {
 //           consoleForm.ConsoleText.Items.Add(text);
 //       }

        private void ConsoleText_SelectedIndexChanged(object sender, EventArgs e)
        {

        }
    }
}
