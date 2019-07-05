using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace VisualCompiler
{
    // This class builds the table to be used by the OFP to select the action
    // to be executed when a key is pushed on the currently displayed page.
    public class BuildTable
    {
 //       private BuildTableForm enterAction;
    //    private Form2 ofp;

        public struct CompilerDataTable
        {
 //           public BuildTableForm.Key key;
 //           public BuildTableForm.Page page;
            public string action; // associated with key and displayed page
        }

        public class CompilerTable
        {
            public int count;
            public CompilerDataTable[] list = new CompilerDataTable[50];
        }

        public CompilerTable compilerTable = new CompilerTable();

 //       public BuildTable(BuildTableForm form) //, Form2 form2)
 //       {
 //           enterAction = form;
 //   //        ofp = form2;
 //           compilerTable.count = 0;
 //           compilerTable.list[0].key = BuildTableFormx.Key.LSKL1; // dummy since count is 0
 //       } // end constructor

 //       public void AddToTable(BuildTableForm.Key key, BuildTableForm.Page page)
 //       {
 //           string actionName = "";
 //           int loopCount = 0;
 //           while(true)
 //           {
 //               actionName = enterAction.actionName; 
 //               if (!enterAction.actionNameAvailable)
 //               {
 //                   loopCount++;
 //                   if (loopCount == 20)
 //                   {
 //                       MessageBoxButtons buttons = MessageBoxButtons.OK;
 //                       DialogResult result;
 //                       string message =
 //                           "No Action name. An Action name must be supplied. Then reselect Key.";
 //                       string caption = "Warning";
 //                       result = MessageBox.Show(message, caption, buttons);
 //                       return;
 //                   }
 //           	    Thread.Sleep(1000); // to give operator time to enter the name
 //           	}
 //           	else
 //           	{
 //                   break; // exit loop
 //               }
 //           }
 //           if (CheckValues(key, page, actionName))
 //           {
 //               int index = compilerTable.count;
 //               compilerTable.list[index].key = key;
 //               if (enterAction.CheckGeneralKey(key))
 //               { compilerTable.list[index].page = BuildTableFormx.Page.DC; } 
 //               else
 //               { compilerTable.list[index].page = page; }
 //               compilerTable.list[index].action = actionName;
 //               compilerTable.count++;
 //               enterAction.actionName = "";
 //               enterAction.actionNameAvailable = false;
 //               enterAction.ActionNameClear();
 //           }

//         } // end AddToTable

 //       private bool CheckValues(BuildTableForm.Key key, BuildTableFormx.Page page,
 //                                string actionName)
 //       {
 //           MessageBoxButtons buttons = MessageBoxButtons.YesNo;
 //           DialogResult result;

 //           bool ok = true;
 //           for (int i = 0; i < compilerTable.count; i++)
 //           {
 //               if (compilerTable.list[i].action == actionName)
 //               {
 //                   string message = 
 //                       "Duplicate Action name. Did you mean to assign again?";
 //                   string caption = "Warning";
 //                   result = MessageBox.Show(message, caption, buttons);
 //                   if (result == System.Windows.Forms.DialogResult.No)
 //                   {
 //                       ok = false;
 //                       break; // exit loop
 //                   }
 //               }
 //               if (enterAction.CheckGeneralKey(key)) // displayed page doesn't 
 //               {                                     //   matter for general keys
 //                   return true;
 //               }
 //               if ((compilerTable.list[i].page == page) &&
 //                   (compilerTable.list[i].key == key))
 //               {
 //                   string message =
 //                       "Duplicate Page and Key combination. Did you mean to assign again?";
 //                   string caption = "Warning";
 //                   result = MessageBox.Show(message, caption, buttons);
 //                   if (result == System.Windows.Forms.DialogResult.No)
 //                   {
 //                       ok = false;
 //                       break; // exit loop
 //                   }
 //               }
 //           }
 //           return ok;
 //       } // end CheckValues

 /*       public string Lookup(BuildTableForm.Key key, BuildTableFormx.Page page)
        {
            if (enterAction.CheckGeneralKey(key)) // displayed page doesn't matter
            {
                for (int i = 0; i < compilerTable.count; i++)
                {
                    if (compilerTable.list[i].key == key)
                    {
                        return compilerTable.list[i].action;
                    }
                }
            }
            else
            {
                for (int i = 0; i < compilerTable.count; i++)
                {
                    if ((compilerTable.list[i].page == page) &&
                        (compilerTable.list[i].key == key))
                    {
                        return compilerTable.list[i].action;
                    }
                }
            }
            return "";
        } // end Lookup */

    } // end class BuildTable 

} // end namespace
