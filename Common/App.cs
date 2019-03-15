using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisualCompiler
{
    static public class App
    {

        public static int applicationId; // the local numeric appId

        private static bool AllowFrameworkTopics = true;
        // Only allow FrameworkTopics to be registered until after Remote.   
        // After return from the Launch procedure the application specific user
        // components will be installed where the use of the framework topics 
        // can not be registered with the Library.

        // Obtain file path by combining directory and file name
        //        unsafe char* ObtainFilePath()
 /*       static string ObtainFilePath()
        {
            string startDir;    // directory to use for application id

            return " "; // filePath;

        } // end ObtainFilePath */

        // Initialize application with operating system.
        static private void InitApplication() //string path)
        {
            Topic.Initialize();         // prior to executing the
            Library.Initialize();       //   threads and in place
            Component.Initialize();     //   of constructors for
            Delivery.Initialize();      //   static classes
            Configuration.Initialize(); //path);
            Remote.Initialize();

        } // end InitApplication

        // Launch the component threads of the general application.
        static public void Launch(Component.ApplicationId appId) //, string path)
        {
            applicationId = appId.id;

            InitApplication(); //path); // initialize the application

            Remote.Launch(); 
            // Return to the particular instance of the Program class to
            // install the components of the particular application and
            // then create the threads for the components.

            // Disallow further registration of framework topics.
            AllowFrameworkTopics = false;

        } // end Launch function

        static public bool FrameworkTopicsAllowed()
        {
            return AllowFrameworkTopics;
        } //  end FrameworkTopicsAllowed

    } // end class App
} // end namespace
