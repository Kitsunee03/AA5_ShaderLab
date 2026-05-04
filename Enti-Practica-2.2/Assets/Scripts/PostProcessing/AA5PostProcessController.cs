using System;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Controls;

public class AA5PostProcessController : MonoBehaviour
{
    [Serializable]
    private struct MaterialBinding
    {
        public Material material;
        public Key key;
    }

    [SerializeField]
    private MaterialBinding[] bindings = Array.Empty<MaterialBinding>();
    private static readonly int EnableEffectId = Shader.PropertyToID("_ENABLE_EFFECT");

    private void Update()
    {
        var kb = Keyboard.current;
        if (kb == null) { return; }

        for (int i = 0; i < bindings.Length; i++)
        {
            KeyControl keyControl = kb[bindings[i].key];
            if (keyControl != null && keyControl.wasPressedThisFrame)
            {
                ToggleMaterial(bindings[i].material);
            }
        }
    }

    private static void ToggleMaterial(Material mat)
    {
        if (mat == null || !mat.HasProperty(EnableEffectId)) { return; }

        bool isEnabled = mat.GetFloat(EnableEffectId) > 0.5f;
        mat.SetFloat(EnableEffectId, isEnabled ? 0f : 1f);
    }
}