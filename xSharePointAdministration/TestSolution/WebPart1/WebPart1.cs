using System;
using System.ComponentModel;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using Microsoft.SharePoint;
using Microsoft.SharePoint.WebControls;

namespace TestSolution.WebPart1
{
    [ToolboxItemAttribute(false)]
    public class WebPart1 : WebPart
    {
        protected override void CreateChildControls()
        {
            this.Controls.Add(new LiteralControl("Hello World!"));
        }
    }
}
