namespace VisualCompiler
{
    partial class ConsoleForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.ConsoleText = new System.Windows.Forms.ListBox();
            this.SuspendLayout();
            // 
            // ConsoleText
            // 
            this.ConsoleText.FormattingEnabled = true;
            this.ConsoleText.ItemHeight = 16;
            this.ConsoleText.Location = new System.Drawing.Point(4, 9);
            this.ConsoleText.Name = "ConsoleText";
            this.ConsoleText.Size = new System.Drawing.Size(770, 372);
            this.ConsoleText.TabIndex = 0;
            this.ConsoleText.SelectedIndexChanged += 
                new System.EventHandler(this.ConsoleText_SelectedIndexChanged);
            // 
            // ConsoleForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(776, 393);
            this.Controls.Add(this.ConsoleText);
            this.Name = "ConsoleForm";
            this.Text = "ConsoleForm";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.ListBox ConsoleText;
    }
}