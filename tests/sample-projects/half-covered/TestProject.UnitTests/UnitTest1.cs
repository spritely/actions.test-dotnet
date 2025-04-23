namespace TestProject.UnitTests;

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        var result = Class1.Covered("test");
        Assert.Equal("test", result);
    }
}
