using Newtonsoft.Json;
namespace Cbsp.Foundation.Network.Api.Models
{

    public partial class AzDevopsGit
    {
        [JsonProperty("refUpdates")]
        public RefUpdate[] RefUpdates { get; set; }

        [JsonProperty("commits")]
        public Commit[] Commits { get; set; }
    }

    public partial class Commit
    {
        [JsonProperty("comment")]
        public string Comment { get; set; }

        [JsonProperty("changes")]
        public Change[] Changes { get; set; }
    }

    public partial class Change
    {
        [JsonProperty("changeType")]
        public string ChangeType { get; set; }

        [JsonProperty("item")]
        public Item Item { get; set; }

        [JsonProperty("newContent")]
        public NewContent NewContent { get; set; }
    }

    public partial class Item
    {
        [JsonProperty("path")]
        public string Path { get; set; }
    }

    public partial class NewContent
    {
        [JsonProperty("content")]
        public string Content { get; set; }

        [JsonProperty("contentType")]
        public string ContentType { get; set; }
    }

    public partial class RefUpdate
    {
        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("oldObjectId")]
        public string OldObjectId { get; set; }
    }
}
