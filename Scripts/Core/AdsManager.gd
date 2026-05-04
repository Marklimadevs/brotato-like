extends Node

# AdsManager — autoload singleton.
# Detecta o SDK do CrazyGames quando o jogo roda dentro do portal deles.
# Fora da web ou em desenvolvimento local, fica em modo stub (chamadas
# de ad sempre fazem fallback para o callback de "skip", sem travar nada).
#
# Uso futuro (quando for implementar rewarded ads):
#   AdsManager.request_rewarded_ad(
#       func(): print("ad concluído, conceder reward"),
#       func(): print("ad pulado/falhou, sem reward"),
#   )

var _sdk_available: bool = false


func _ready() -> void:
	if not OS.has_feature("web"):
		print("AdsManager: rodando fora da web — modo stub.")
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		print("AdsManager: JavaScriptBridge não disponível.")
		return
	# Checa se o SDK do CrazyGames foi carregado pelo head_include
	var result = JavaScriptBridge.eval("typeof window.CrazyGames !== 'undefined'", true)
	_sdk_available = (result == true)
	if _sdk_available:
		print("AdsManager: CrazyGames SDK detectado ✓")
	else:
		print("AdsManager: SDK do CrazyGames não disponível (provavelmente rodando fora do portal).")


func is_available() -> bool:
	return _sdk_available


# Stubs — quando for implementar ads, plugar JavaScriptBridge aqui.
# Por enquanto sempre chama o callback de "skip" (sem reward).

func request_rewarded_ad(on_success: Callable, on_skip: Callable) -> void:
	if not _sdk_available:
		on_skip.call()
		return
	# TODO: integrar com CrazyGames SDK v3 — algo como:
	# JavaScriptBridge.eval("""
	#   window.CrazyGames.SDK.ad.requestAd('rewarded')
	#     .then(() => godotCallback('success'))
	#     .catch(() => godotCallback('skip'));
	# """, true)
	on_skip.call()


func request_midgame_ad() -> void:
	if not _sdk_available:
		return
	# TODO: window.CrazyGames.SDK.ad.requestAd('midgame')
