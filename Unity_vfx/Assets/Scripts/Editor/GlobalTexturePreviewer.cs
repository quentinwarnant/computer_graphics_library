using UnityEngine;
using UnityEditor;

public class GlobalTexturePreviewer : EditorWindow
{
    [MenuItem("Q/Global Texture previewer")]
    static void Init()
    {
        // Get existing open window or if none, make a new one:
        GlobalTexturePreviewer window = (GlobalTexturePreviewer)EditorWindow.GetWindow(typeof(GlobalTexturePreviewer));
        window.Show();
    }

    [SerializeField] string m_globalTexName;

    Texture m_tex;

    // Update is called once per frame
    void OnGUI()
    {
        m_globalTexName = GUILayout.TextField(m_globalTexName);
        m_tex = Shader.GetGlobalTexture(m_globalTexName);

        if (m_tex != null)
        {
            GUILayout.Box(m_tex);
        }
    }
}
