namespace Cbsp.Foundation.Network.Api.Models
{
    public partial class Branch
    {
        public string Id { get; set; }
        public string FirstCommitId { get; set; }
        public bool Success { get; set; }
        public string Name { get; set; }
    }
}