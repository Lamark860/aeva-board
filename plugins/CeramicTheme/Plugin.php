<?php

namespace Kanboard\Plugin\CeramicTheme;

use Kanboard\Core\Plugin\Base;

/**
 * Брендовая тема Aeva для Kanboard.
 *
 * Подключает свой CSS поверх дефолтного через asset-хук `template:layout:css`
 * (см. https://docs.kanboard.org/v1/plugins/hooks/). CSS грузится последним и
 * переопределяет стандартные стили. Образец — kanboard/plugin-example-css.
 */
class Plugin extends Base
{
    public function initialize()
    {
        // CSS-тема (грузится последней, переопределяет дефолтные стили Kanboard).
        $this->hook->on('template:layout:css', array(
            'template' => 'plugins/CeramicTheme/Assets/css/skin.css',
        ));

        // Лёгкий JS-слой UX-доводок (например, закрытие модалки по клику на фон).
        $this->hook->on('template:layout:js', array(
            'template' => 'plugins/CeramicTheme/Assets/js/theme.js',
        ));
    }

    public function getPluginName()
    {
        return 'CeramicTheme';
    }

    public function getPluginDescription()
    {
        return 'Брендовая тема Aeva (Playfair Display, терракота) — палитра витрины aevashop.ru';
    }

    public function getPluginAuthor()
    {
        return 'Aeva';
    }

    public function getPluginVersion()
    {
        return '1.0.0';
    }

    public function getPluginHomepage()
    {
        return 'https://aevashop.ru';
    }
}
