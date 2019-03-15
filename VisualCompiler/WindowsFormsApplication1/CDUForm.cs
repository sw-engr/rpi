using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace VisualCompiler
{
    public partial class CDUForm : Form
    {
        static private ComOFP comOFP;
        static private CDUForm cduForm = new CDUForm();

        // The type to be returned by ComOFP
        public struct Result
        {
            public bool success;
            public string text;
        }

        public enum Key
        { // the line select keys and a portion of the other non-alphanumeric keys
            LSKL1,
            LSKL2,
            LSKL3,
            LSKL4,
            LSKL5,
            LSKL6,
            LSKR1,
            LSKR2,
            LSKR3,
            LSKR4,
            LSKR5,
            LSKR6,
            DATA,
            DIR,
            FLIGHTPLAN,
            INIT,
            PERF,
            PROG,
            PREV,
            NEXT,
            UP,
            DOWN
        } // end enum Key
        
        public CDUForm()
        {
            InitializeComponent();
            comOFP = new ComOFP();
        } // end constructor

        public void DisplayPageTitle(string text)
        {
            // Display new Title if key push was to known page
            if ((text == "DIR") || (text == "PROG") || (text == "PERF") ||
                (text == "INIT") || (text == "DATA") || (text == "FLIGHTPLAN"))
            {
                DisplayLabel.Text = text;
            }
            // Display result in text box no matter what
            textBoxL2.Text = text;
        } // end DisplayPageTitle

        // This method is to react to a key push
        private void React(Key key)
        {
           ConsoleOut.WriteLine("React " + key);
           if (ComOFP.connected) // fully connected to remote app
           {
              // Send key to OFP application
              Result result = new Result();
              result = comOFP.TreatKey(key);
              if (result.success)
              {
                  DisplayPageTitle(result.text);
              }
              else
              {
                  textBoxL2.Text = "key ignored";
              }
           }

        } // end React

        //**********************************************************************
        // Beginning of event handlers

        // These event handlers all invoke the React method to allow a common
        // method to determine whether in the build table mode or the OFP mode.
        // This allows a common form to be used to interpret the button push
        // as from the visual compiler / table builder or from the OFP using
        // the created table.
        private void LSKL1_Click(object sender, EventArgs e)
        {
            React(Key.LSKL1);
        }

        private void LSKL2_Click(object sender, EventArgs e)
        {
            React(Key.LSKL2);
        }

        private void LSKL3_Click(object sender, EventArgs e)
        {
            React(Key.LSKL3);
        }

        private void LSKL4_Click(object sender, EventArgs e)
        {
            React(Key.LSKL4);
        }

        private void LSKL5_Click(object sender, EventArgs e)
        {
            React(Key.LSKL5);
        }

        private void LSKL6_Click(object sender, EventArgs e)
        {
            React(Key.LSKL6);
        }

        private void LSKR1_Click(object sender, EventArgs e)
        {
            React(Key.LSKR1);
        }

        private void LSKR2_Click(object sender, EventArgs e)
        {
            React(Key.LSKR2);
        }

        private void LSKR3_Click(object sender, EventArgs e)
        {
            React(Key.LSKR3);
        }

        private void LSKR4_Click(object sender, EventArgs e)
        {
            React(Key.LSKR4);
        }

        private void LSKR5_Click(object sender, EventArgs e)
        {
            React(Key.LSKR5);
        }

        private void LSKR6_Click(object sender, EventArgs e)
        {
            React(Key.LSKR6);
        }

        private void DIR_Click(object sender, EventArgs e)
        {
            React(Key.DIR);
        }

        private void PROG_Click(object sender, EventArgs e)
        {
            React(Key.PROG);
        }

        private void PERF_Click(object sender, EventArgs e)
        {
            React(Key.PERF);
        }

        private void INIT_Click(object sender, EventArgs e)
        {
            React(Key.INIT);
        }

        private void DATA_Click(object sender, EventArgs e)
        {
            React(Key.DATA);
        }

        private void FPLAN_Click(object sender, EventArgs e)
        {
            React(Key.FLIGHTPLAN);
        }

        private void PREV_Click(object sender, EventArgs e)
        {
            React(Key.PREV);
        }

        private void NEXT_Click(object sender, EventArgs e)
        {
            React(Key.NEXT);
        }

        private void UP_Click(object sender, EventArgs e)
        {
            React(Key.UP);
        }

        private void DOWN_Click(object sender, EventArgs e)
        {
            React(Key.DOWN);
        }

        private void DisplayLabel_Click(object sender, EventArgs e)
        {

        }

    } // end class

} // end namespace
